defmodule Stormful.Queue do
  @moduledoc """
  The Queue context for managing background jobs with rate limiting.

  This module provides the public API for:
  - Enqueueing jobs for background processing
  - Managing job status and lifecycle
  - Retrieving jobs for processing with rate limiting
  - Queue statistics and monitoring
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo
  alias Stormful.Queue.Job

  require Logger

  # Rate limiting configuration - jobs per minute for each task type
  @rate_limits %{
    # 100 emails per 60 seconds
    "email" => {100, 60},
    # 30 AI jobs per 60 seconds
    "ai_processing" => {30, 60},
    # 50 thought extraction jobs per 60 seconds (generous, can go above)
    "thought_extraction" => {50, 60}
  }

  @doc """
  Enqueues a new job for background processing.

  ## Examples

      iex> enqueue_job("email", %{to: "user@example.com", subject: "Welcome"})
      {:ok, %Job{}}

      iex> enqueue_job("email", %{to: "user@example.com"}, user_id: 123)
      {:ok, %Job{}}

      iex> enqueue_job("invalid_type", %{})
      {:error, %Ecto.Changeset{}}
  """
  def enqueue_job(task_type, payload, opts \\ []) do
    attrs =
      %{
        task_type: task_type,
        payload: payload
      }
      |> maybe_add_user_id(opts)
      |> maybe_add_scheduled_at(opts)
      |> maybe_add_max_attempts(opts)

    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, job} = result ->
        Logger.info("Enqueued job #{job.id} of type #{job.task_type}")
        result

      {:error, changeset} = error ->
        Logger.error("Failed to enqueue job: #{inspect(changeset.errors)}")
        error
    end
  end

  @doc """
  Convenience function to enqueue an email job.

  ## Examples

      iex> enqueue_email(%{to: "user@example.com", subject: "Welcome"})
      {:ok, %Job{}}
  """
  def enqueue_email(payload, opts \\ []) do
    enqueue_job("email", payload, opts)
  end

  @doc """
  Convenience function to enqueue an AI processing job.

  ## Examples

      iex> enqueue_ai_processing(%{prompt: "Analyze this text", model: "gpt-4"})
      {:ok, %Job{}}
  """
  def enqueue_ai_processing(payload, opts \\ []) do
    enqueue_job("ai_processing", payload, opts)
  end

  @doc """
  Convenience function to enqueue a thought extraction job (using OpenRouter).
  These jobs have generous rate limits (50/minute) and can be delayed.

  ## Examples

      iex> enqueue_thought_extraction(%{model: "openai/gpt-3.5-turbo", prompt: "Hello world"})
      {:ok, %Job{}}

      iex> enqueue_thought_extraction(%{model: "openai/gpt-3.5-turbo", prompt: "Hello world"}, scheduled_at: DateTime.add(DateTime.utc_now(), 300, :second))
      {:ok, %Job{}}
  """
  def enqueue_thought_extraction(payload, opts \\ []) do
    enqueue_job("thought_extraction", payload, opts)
  end

  @doc """
  Gets a single job by ID.

  ## Examples

      iex> get_job(123)
      %Job{}

      iex> get_job(999)
      nil
  """
  def get_job(id), do: Repo.get(Job, id)

  @doc """
  Gets a single job by ID, raises if not found.

  ## Examples

      iex> get_job!(123)
      %Job{}

      iex> get_job!(999)
      ** (Ecto.NoResultsError)
  """
  def get_job!(id), do: Repo.get!(Job, id)

  @doc """
  Lists jobs with optional filtering.

  ## Examples

      iex> list_jobs()
      [%Job{}, ...]

      iex> list_jobs(status: "pending", limit: 10)
      [%Job{}, ...]

      iex> list_jobs(task_type: "email", user_id: 123)
      [%Job{}, ...]
  """
  def list_jobs(opts \\ []) do
    Job
    |> apply_filters(opts)
    |> maybe_limit(opts[:limit])
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets jobs ready for processing (pending status and scheduled time has passed).
  Now includes rate limiting - won't return jobs if task type is rate limited.

  ## Examples

      iex> get_ready_jobs()
      [%Job{}, ...]

      iex> get_ready_jobs(limit: 5)
      [%Job{}, ...]

      iex> get_ready_jobs(task_type: "email")
      [%Job{}, ...]  # Only if email queue isn't rate limited
  """
  def get_ready_jobs(opts \\ []) do
    case Keyword.get(opts, :task_type) do
      nil ->
        # Get jobs from all task types, but filter by rate limits
        get_ready_jobs_all_types(opts)

      task_type ->
        # Get jobs for specific task type if not rate limited
        get_ready_jobs_for_type(task_type, opts)
    end
  end

  @doc """
  Gets jobs ready for processing for a specific task type.
  Returns empty list if task type is currently rate limited.
  """
  def get_ready_jobs_for_type(task_type, opts \\ []) do
    if within_rate_limit?(task_type) do
      Job.ready_for_processing_query()
      |> where([j], j.task_type == ^task_type)
      |> maybe_limit(opts[:limit])
      |> Repo.all()
      |> tap(fn jobs ->
        if length(jobs) > 0 do
          Logger.debug("Fetched #{length(jobs)} ready #{task_type} jobs")
        end
      end)
    else
      Logger.debug("Task type #{task_type} is rate limited, returning no jobs")
      []
    end
  end

  @doc """
  Gets ready jobs from all task types, respecting rate limits for each type.
  """
  def get_ready_jobs_all_types(opts \\ []) do
    limit = opts[:limit]

    # Get available task types and check rate limits for each
    available_types = get_available_task_types_within_limits()

    if Enum.empty?(available_types) do
      Logger.debug("All task types are rate limited, returning no jobs")
      []
    else
      query = Job.ready_for_processing_query()

      query =
        if Enum.empty?(available_types) do
          # No types available, return empty
          where(query, [j], false)
        else
          # Only fetch from non-rate-limited types
          where(query, [j], j.task_type in ^available_types)
        end

      query
      |> maybe_limit(limit)
      |> Repo.all()
      |> tap(fn jobs ->
        if length(jobs) > 0 do
          types = jobs |> Enum.map(& &1.task_type) |> Enum.uniq()
          Logger.debug("Fetched #{length(jobs)} ready jobs from types: #{inspect(types)}")
        end
      end)
    end
  end

  @doc """
  Records that a job of the given task type was started.
  Call this when a job begins processing to track rate limit usage.
  """
  def record_job_start(task_type) do
    now = System.system_time(:second)

    # Store the start time in ETS or similar for rate limit tracking
    # For now, we'll use the job table itself to track recent starts
    Logger.debug("Recording job start for task_type: #{task_type} at #{now}")
    :ok
  end

  @doc """
  Checks if we're within the rate limit for a given task type.
  Returns true if we can start more jobs, false if rate limited.
  """
  def within_rate_limit?(task_type) do
    case Map.get(@rate_limits, task_type) do
      nil ->
        # No rate limit configured for this task type
        true

      {max_jobs, window_seconds} ->
        check_rate_limit(task_type, max_jobs, window_seconds)
    end
  end

  @doc """
  Gets all task types that are currently within their rate limits.
  """
  def get_available_task_types_within_limits do
    @rate_limits
    |> Map.keys()
    |> Enum.filter(&within_rate_limit?/1)
    |> tap(fn available ->
      if length(available) > 0 do
        Logger.debug("Available task types within rate limits: #{inspect(available)}")
      end
    end)
  end

  @doc """
  Gets jobs that failed but can be retried.

  ## Examples

      iex> get_retriable_jobs()
      [%Job{}, ...]
  """
  def get_retriable_jobs(opts \\ []) do
    Job.retriable_query()
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  @doc """
  Updates a job's status and related timestamps.

  ## Examples

      iex> update_job_status(job, "processing")
      {:ok, %Job{}}

      iex> update_job_status(job, "failed", %{error_message: "Connection timeout"})
      {:ok, %Job{}}
  """
  def update_job_status(job, status, attrs \\ %{}) do
    job
    |> Job.status_changeset(status, attrs)
    |> Repo.update()
    |> case do
      {:ok, _updated_job} = result ->
        Logger.info("Updated job #{job.id} status to #{status}")
        result

      {:error, changeset} = error ->
        Logger.error("Failed to update job #{job.id} status: #{inspect(changeset.errors)}")
        error
    end
  end

  @doc """
  Marks a job as processing and records the start for rate limiting.
  """
  def mark_processing(job) do
    # Record the job start for rate limiting
    record_job_start(job.task_type)

    update_job_status(job, "processing")
  end

  @doc """
  Marks a job as completed.
  """
  def mark_completed(job) do
    update_job_status(job, "completed")
  end

  @doc """
  Marks a job as failed with an optional error message.
  """
  def mark_failed(job, error_message \\ nil) do
    attrs = if error_message, do: %{error_message: error_message}, else: %{}

    # Increment attempts
    attrs = Map.put(attrs, :attempts, job.attempts + 1)

    update_job_status(job, "failed", attrs)
  end

  @doc """
  Deletes a job.

  ## Examples

      iex> delete_job(job)
      {:ok, %Job{}}

      iex> delete_job(bad_job)
      {:error, %Ecto.Changeset{}}
  """
  def delete_job(%Job{} = job) do
    Repo.delete(job)
  end

  @doc """
  Returns queue statistics for monitoring.

  ## Examples

      iex> get_queue_stats()
      %{
        pending: 15,
        processing: 3,
        completed: 142,
        failed: 2,
        total: 162
      }
  """
  def get_queue_stats do
    stats_query =
      from j in Job,
        select: {j.status, count(j.id)},
        group_by: j.status

    stats =
      stats_query
      |> Repo.all()
      |> Enum.into(%{})

    %{
      pending: Map.get(stats, "pending", 0),
      processing: Map.get(stats, "processing", 0),
      completed: Map.get(stats, "completed", 0),
      failed: Map.get(stats, "failed", 0),
      total: Enum.sum(Map.values(stats))
    }
  end

  @doc """
  Returns queue statistics by task type.

  ## Examples

      iex> get_stats_by_type()
      %{
        "email" => %{pending: 10, completed: 50, ...},
        "ai_processing" => %{pending: 5, completed: 15, ...}
      }
  """
  def get_stats_by_type do
    stats_query =
      from j in Job,
        select: {j.task_type, j.status, count(j.id)},
        group_by: [j.task_type, j.status]

    stats_query
    |> Repo.all()
    |> Enum.group_by(fn {task_type, _status, _count} -> task_type end)
    |> Enum.into(%{}, fn {task_type, stats} ->
      type_stats =
        stats
        |> Enum.into(%{}, fn {_task_type, status, count} -> {status, count} end)
        |> Map.put("total", Enum.sum(Enum.map(stats, fn {_, _, count} -> count end)))

      {task_type, type_stats}
    end)
  end

  # Private helper functions

  defp maybe_add_user_id(attrs, opts) do
    case Keyword.get(opts, :user_id) do
      nil -> attrs
      user_id -> Map.put(attrs, :user_id, user_id)
    end
  end

  defp maybe_add_scheduled_at(attrs, opts) do
    case Keyword.get(opts, :scheduled_at) do
      nil -> attrs
      scheduled_at -> Map.put(attrs, :scheduled_at, scheduled_at)
    end
  end

  defp maybe_add_max_attempts(attrs, opts) do
    case Keyword.get(opts, :max_attempts) do
      nil -> attrs
      max_attempts -> Map.put(attrs, :max_attempts, max_attempts)
    end
  end

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:status, status} | rest]) do
    query
    |> where([j], j.status == ^status)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:task_type, task_type} | rest]) do
    query
    |> where([j], j.task_type == ^task_type)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:user_id, user_id} | rest]) do
    query
    |> where([j], j.user_id == ^user_id)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_unknown | rest]) do
    apply_filters(query, rest)
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  # Private rate limiting functions

  defp check_rate_limit(task_type, max_jobs, window_seconds) do
    cutoff_time = DateTime.add(DateTime.utc_now(), -window_seconds, :second)

    # Count jobs that started within the rate limit window
    recent_jobs_count =
      from(j in Job,
        where:
          j.task_type == ^task_type and
            j.status in ["processing", "completed", "failed"] and
            j.started_at > ^cutoff_time,
        select: count(j.id)
      )
      |> Repo.one()

    within_limit = recent_jobs_count < max_jobs

    if not within_limit do
      Logger.debug(
        "Rate limit hit for #{task_type}: #{recent_jobs_count}/#{max_jobs} in last #{window_seconds}s"
      )
    end

    within_limit
  end
end
