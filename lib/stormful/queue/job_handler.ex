defmodule Stormful.Queue.JobHandler do
  @moduledoc """
  Behavior for implementing job handlers in the queue system.

  Each job type should have its own handler module that implements this behavior.
  This allows for clean separation of concerns and easy extensibility.

    ## Example Implementation

      defmodule MyApp.Jobs.EmailHandler do
        @behaviour Stormful.Queue.JobHandler

        @impl true
        def handle_job(%{payload: payload, user_id: user_id} = job) do
          # Your email processing logic here
          {:ok, %{delivered_at: DateTime.utc_now()}}
        end

        @impl true
        def validate_payload(payload) do
          required_fields = ["to", "subject"]
          missing_fields = Enum.filter(required_fields, fn field ->
            not Map.has_key?(payload, field)
          end)

          if Enum.empty?(missing_fields) do
            :ok
          else
            {:error, "Missing required fields: " <> Enum.join(missing_fields, ", ")}
          end
        end
      end
  """

  @doc """
  Handles the execution of a job.

  Receives the full job struct and should return either:
  - `{:ok, result}` for successful processing
  - `{:error, reason}` for failed processing

  The result will be logged and can be used for monitoring/debugging.
  """
  @callback handle_job(job :: map()) :: {:ok, any()} | {:error, any()}

  @doc """
  Validates the job payload before processing.

  This is called before `handle_job/1` to ensure the payload has all required fields.
  Should return `:ok` if valid, or `{:error, reason}` if invalid.

  This callback is optional - if not implemented, validation is skipped.
  """
  @callback validate_payload(payload :: map()) :: :ok | {:error, String.t()}

  @optional_callbacks [validate_payload: 1]

  @doc """
  Helper function to check if a module implements the JobHandler behavior.
  """
  def implements_behavior?(module) do
    module.module_info(:attributes)
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(__MODULE__)
  rescue
    _ -> false
  end
end
