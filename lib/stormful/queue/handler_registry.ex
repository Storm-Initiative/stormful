defmodule Stormful.Queue.HandlerRegistry do
  @moduledoc """
  Registry for job handlers in the queue system.

  This module provides automatic handler discovery and routing based on job types.
  It uses naming conventions to map job types to their corresponding handler modules.

  ## Handler Discovery

  Handlers are discovered using the following naming convention:
  - Job type: "email" → Handler: Stormful.Queue.Handlers.EmailHandler
  - Job type: "ai_processing" → Handler: Stormful.Queue.Handlers.AiProcessingHandler
  - Job type: "thought_extraction" → Handler: Stormful.Queue.Handlers.ThoughtExtractionHandler

  ## Custom Handler Registration

  You can also register custom handlers explicitly:

      HandlerRegistry.register_handler("custom_job", MyApp.CustomJobHandler)
  """

  require Logger

  @default_handlers %{
    "email" => Stormful.Queue.Handlers.EmailHandler
  }

  @doc """
  Gets the handler module for a given job type.

  First checks for explicitly registered handlers, then falls back to
  naming convention-based discovery.

  ## Examples

      iex> HandlerRegistry.get_handler("email")
      {:ok, Stormful.Queue.Handlers.EmailHandler}

      iex> HandlerRegistry.get_handler("unknown_type")
      {:error, "No handler found for job type: unknown_type"}
  """
  def get_handler(job_type) do
    case Map.get(registered_handlers(), job_type) do
      nil ->
        # Try to discover handler by naming convention
        discover_handler(job_type)

      handler_module ->
        validate_handler(handler_module, job_type)
    end
  end

  @doc """
  Registers a custom handler for a job type.

  The handler module must implement the JobHandler behavior.

  ## Examples

      iex> HandlerRegistry.register_handler("webhook", MyApp.WebhookHandler)
      :ok

      iex> HandlerRegistry.register_handler("invalid", NonExistentModule)
      {:error, "Handler module does not exist or implement JobHandler behavior"}
  """
  def register_handler(job_type, handler_module) do
    if valid_handler?(handler_module) do
      :persistent_term.put(
        {__MODULE__, :handlers},
        Map.put(registered_handlers(), job_type, handler_module)
      )

      Logger.info(
        "Registered custom handler for job type '#{job_type}': #{inspect(handler_module)}"
      )

      :ok
    else
      {:error, "Handler module does not exist or implement JobHandler behavior"}
    end
  end

  @doc """
  Lists all registered handlers.

  ## Examples

      iex> HandlerRegistry.list_handlers()
      %{
        "email" => Stormful.Queue.Handlers.EmailHandler,
        "ai_processing" => Stormful.Queue.Handlers.AiProcessingHandler,
        "custom_job" => MyApp.CustomJobHandler
      }
  """
  def list_handlers do
    registered_handlers()
  end

  @doc """
  Validates that all registered handlers implement the JobHandler behavior.

  Returns a list of invalid handlers, if any.

  ## Examples

      iex> HandlerRegistry.validate_all_handlers()
      []

      iex> HandlerRegistry.validate_all_handlers()
      [{"invalid_job", SomeInvalidModule}]
  """
  def validate_all_handlers do
    registered_handlers()
    |> Enum.filter(fn {_job_type, handler_module} ->
      not valid_handler?(handler_module)
    end)
  end

  # Private functions

  defp registered_handlers do
    case :persistent_term.get({__MODULE__, :handlers}, nil) do
      nil ->
        # Initialize with default handlers on first access
        :persistent_term.put({__MODULE__, :handlers}, @default_handlers)
        @default_handlers

      handlers ->
        handlers
    end
  end

  defp discover_handler(job_type) do
    # Convert job_type to module name using naming convention
    # "email" -> "EmailHandler"
    # "ai_processing" -> "AiProcessingHandler"
    module_name =
      job_type
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join("")
      |> Kernel.<>("Handler")

    handler_module = Module.concat([Stormful.Queue.Handlers, module_name])

    validate_handler(handler_module, job_type)
  end

  defp validate_handler(handler_module, job_type) do
    if valid_handler?(handler_module) do
      {:ok, handler_module}
    else
      {:error, "No handler found for job type: #{job_type}"}
    end
  end

  defp valid_handler?(handler_module) do
    try do
      # Check if module exists and is loaded
      # Check if it implements the JobHandler behavior
      Code.ensure_loaded?(handler_module) and
        Stormful.Queue.JobHandler.implements_behavior?(handler_module)
    rescue
      _ -> false
    end
  end
end
