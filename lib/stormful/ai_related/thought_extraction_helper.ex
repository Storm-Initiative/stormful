defmodule Stormful.AiRelated.ThoughtExtractionHelper do
  @moduledoc """
  Helper functions for working with thought extraction jobs through the queue system.

  This module provides convenient wrappers for enqueueing thought extraction tasks
  using OpenRouter through the background job system.
  """

  alias Stormful.Queue

    @doc """
  Enqueue a simple thought extraction task.

  ## Examples

      iex> ThoughtExtractionHelper.complete_async("openai/gpt-3.5-turbo", "Hello world")
      {:ok, %Job{}}

      iex> ThoughtExtractionHelper.complete_async("openai/gpt-3.5-turbo", "Analyze this", max_tokens: 100)
      {:ok, %Job{}}
  """
  def complete_async(model, prompt, opts \\ []) do
    payload = %{
      "model" => model,
      "prompt" => prompt
    }
    |> maybe_add_ai_options(opts)

    queue_opts = extract_queue_options(opts)

    Queue.enqueue_thought_extraction(payload, queue_opts)
  end

  @doc """
  Enqueue a delayed thought extraction task.

  ## Examples

      # Process in 5 minutes
      iex> ThoughtExtractionHelper.complete_delayed("openai/gpt-3.5-turbo", "Hello", 300)
      {:ok, %Job{}}

      # Process at specific time
      iex> ThoughtExtractionHelper.complete_delayed("openai/gpt-3.5-turbo", "Hello", DateTime.add(DateTime.utc_now(), 3600, :second))
      {:ok, %Job{}}
  """
  def complete_delayed(model, prompt, delay_or_datetime, opts \\ []) do
    scheduled_at = case delay_or_datetime do
      %DateTime{} = datetime -> datetime
      seconds when is_integer(seconds) -> DateTime.add(DateTime.utc_now(), seconds, :second)
    end

    payload = %{
      "model" => model,
      "prompt" => prompt
    }
    |> maybe_add_ai_options(opts)

    queue_opts =
      extract_queue_options(opts)
      |> Keyword.put(:scheduled_at, scheduled_at)

    Queue.enqueue_thought_extraction(payload, queue_opts)
  end

  @doc """
  Get the status of a thought extraction job.
  """
  def get_job_status(job_id) do
    case Queue.get_job(job_id) do
      nil -> {:error, :not_found}
      job ->
        {:ok, %{
          id: job.id,
          status: job.status,
          attempts: job.attempts,
          error: job.error_message,
          created_at: job.inserted_at,
          scheduled_at: job.scheduled_at,
          started_at: job.started_at,
          completed_at: job.completed_at
        }}
    end
  end

  @doc """
  List recent thought extraction jobs for a user.
  """
  def list_user_jobs(user_id, limit \\ 20) do
    Queue.list_jobs(
      task_type: "thought_extraction",
      user_id: user_id,
      limit: limit
    )
  end

  # Private helper functions

  defp maybe_add_ai_options(payload, opts) do
    ai_options = [:max_tokens, :temperature, :top_p, :seed, :user]

    Enum.reduce(ai_options, payload, fn option, acc ->
      case Keyword.get(opts, option) do
        nil -> acc
        value -> Map.put(acc, Atom.to_string(option), value)
      end
    end)
  end

  defp extract_queue_options(opts) do
    queue_options = [:user_id, :max_attempts, :scheduled_at, :priority]

    Enum.reduce(queue_options, [], fn option, acc ->
      case Keyword.get(opts, option) do
        nil -> acc
        value -> [{option, value} | acc]
      end
    end)
  end
end
