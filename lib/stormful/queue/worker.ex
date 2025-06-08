defmodule Stormful.Queue.Worker do
  @moduledoc """
  Lightweight job dispatcher for the queue system.

  This module acts as the "igniter" that routes jobs to their appropriate handlers.
  It no longer contains job-specific business logic - that has been moved to
  dedicated handler modules for better organization and extensibility.

  ## Job Processing Flow

  1. Receives a job from the processor
  2. Looks up the appropriate handler using the registry
  3. Validates the job payload (if handler supports validation)
  4. Delegates execution to the handler
  5. Returns the result with proper error handling

  ## Adding New Job Types

  To add a new job type, simply:
  1. Create a handler module implementing the JobHandler behavior
  2. Place it in `lib/stormful/queue/handlers/`
  3. Follow the naming convention: `{JobType}Handler`
  4. No changes needed to this dispatcher!

  ## Examples

      # These all work automatically through handler discovery:
      iex> Worker.process_job(email_job)
      {:ok, %{delivered_at: ~U[2025-05-30 19:30:00Z]}}

      iex> Worker.process_job(ai_job)
      {:ok, %{response: "AI analysis complete", tokens_used: 150}}

      iex> Worker.process_job(custom_job)
      {:ok, %{custom_result: "Success"}}
  """

  require Logger

  alias Stormful.Queue.HandlerRegistry

  @doc """
  Main entry point for processing a job.

  Routes the job to the appropriate handler based on job type.
  Handles validation, execution, and error scenarios.
  """
  def process_job(job) do
    Logger.info("Worker dispatching job #{job.id} of type #{job.task_type}")

    case HandlerRegistry.get_handler(job.task_type) do
      {:ok, handler_module} ->
        dispatch_to_handler(job, handler_module)

      {:error, reason} ->
        Logger.error("No handler found for job #{job.id} (#{job.task_type}): #{reason}")
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Unexpected error processing job #{job.id}: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Health check function to verify the worker can process jobs.
  """
  def health_check do
    # Check that the registry can find handlers for known job types
    known_types = ["email", "ai_processing", "thought_extraction"]

    failed_types = Enum.filter(known_types, fn job_type ->
      case HandlerRegistry.get_handler(job_type) do
        {:ok, _} -> false
        {:error, _} -> true
      end
    end)

    if Enum.empty?(failed_types) do
      :ok
    else
      {:error, "Missing handlers for job types: #{Enum.join(failed_types, ", ")}"}
    end
  end

  @doc """
  Returns statistics about job processing performance.
  """
  def get_processing_stats do
    handlers = HandlerRegistry.list_handlers()

    %{
      supported_job_types: Map.keys(handlers),
      registered_handlers: map_size(handlers),
      handler_modules: Map.values(handlers),
      last_health_check: DateTime.utc_now()
    }
  end

  # Private functions

  defp dispatch_to_handler(job, handler_module) do
    Logger.debug("Dispatching job #{job.id} to #{inspect(handler_module)}")

    # Perform validation if the handler supports it
    case validate_with_handler(job, handler_module) do
      :ok ->
        # Execute the job
        handler_module.handle_job(job)

      {:error, reason} ->
        Logger.error("Validation failed for job #{job.id}: #{reason}")
        {:error, "Validation failed: #{reason}"}
    end
  rescue
    error ->
      Logger.error("Handler execution failed for job #{job.id}: #{inspect(error)}")
      {:error, "Handler execution failed: #{inspect(error)}"}
  end

  defp validate_with_handler(job, handler_module) do
    if function_exported?(handler_module, :validate_payload, 1) do
      handler_module.validate_payload(job.payload)
    else
      # Skip validation if handler doesn't implement it
      :ok
    end
  end
end
