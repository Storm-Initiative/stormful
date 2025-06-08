defmodule Stormful.Queue.Handlers.ThoughtExtractionHandler do
  @moduledoc """
  Handles thought extraction job processing through the queue system.

  This handler manages OpenRouter-based thought extraction jobs,
  including prompt processing, AI interaction, and calendar integration.
  """

  @behaviour Stormful.Queue.JobHandler

  require Logger

  alias Stormful.Calendar.CalendarNotifier
  alias Stormful.Accounts

  @impl true
  def validate_payload(payload) do
    required_fields = ["model", "prompt"]

    missing_fields =
      required_fields
      |> Enum.filter(fn field -> not Map.has_key?(payload, field) end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  @impl true
  def handle_job(job) do
    Logger.info("Processing thought extraction job #{job.id}")

    case validate_payload(job.payload) do
      :ok ->
        process_openrouter_request(job)

      {:error, reason} ->
        Logger.error("Invalid thought extraction payload for job #{job.id}: #{reason}")
        {:error, "Invalid thought extraction payload: #{reason}"}
    end
  end

  # Private functions

  defp process_openrouter_request(job) do
    payload = job.payload

    # Extract OpenRouter parameters
    model = payload["model"]
    prompt = payload["prompt"]

    # Build options from payload
    opts = []
    |> maybe_add_option("max_tokens", payload)
    |> maybe_add_option("temperature", payload)
    |> maybe_add_option("top_p", payload)
    |> maybe_add_option("seed", payload)
    |> maybe_add_option("user", payload)

    case Stormful.AiRelated.OpenRouterClient.complete(model, prompt, opts) do
      {:ok, response} ->
        Logger.info("OpenRouter processing completed for job #{job.id}")

        # Extract text from response
        text = case response do
          %{"choices" => [%{"text" => text} | _]} -> text
          _ -> "No text response available"
        end

        # Clean up the AI response format markers
        text = String.replace(text, ~r/^```(json)?\n?/, "")
        text = String.replace(text, ~r/\n?```(json)?$/, "")

        # Parse the AI response to check for calendar events
        calendar_result = process_calendar_from_ai_response(text, job.user_id)

        # Log the thought extraction output
        Logger.info("""

        ═══════════════════════════════════════════════════════════════════
        🧠 THOUGHT EXTRACTION RESULT - Job #{job.id}
        ═══════════════════════════════════════════════════════════════════
        Original Prompt: #{String.slice(prompt, 0, 100)}#{if String.length(prompt) > 100, do: "...", else: ""}

        AI Response: #{text}

        #{format_calendar_result(calendar_result)}

        Model: #{model} | Timestamp: #{DateTime.utc_now()}
        ═══════════════════════════════════════════════════════════════════

        """)

        {:ok, %{
          response: text,
          full_response: response,
          model_used: model,
          prompt_used: prompt,
          calendar_result: calendar_result,
          completed_at: DateTime.utc_now()
        }}

      {:error, reason} ->
        Logger.error("OpenRouter processing failed for job #{job.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp maybe_add_option(opts, key, payload) do
    case Map.get(payload, key) do
      nil -> opts
      value -> [{String.to_atom(key), value} | opts]
    end
  end

  defp process_calendar_from_ai_response(ai_response, user_id) do
    case Jason.decode(ai_response) do
      {:ok, %{"type" => "reminder"} = reminder_data} ->
        case get_user_email(user_id) do
          {:ok, user_email} ->
            case CalendarNotifier.send_reminder_event(user_email, reminder_data, user_id) do
              {:ok, calendar_job} ->
                {:calendar_created, calendar_job}
              {:error, reason} ->
                {:calendar_error, reason}
            end
          {:error, reason} ->
            {:user_error, reason}
        end
      {:ok, _} -> {:no_reminder}
      {:error, _} -> {:no_json}
    end
  rescue
    error -> {:processing_error, error}
  end

  defp get_user_email(user_id) when is_integer(user_id) do
    try do
      user = Accounts.get_user!(user_id)
      {:ok, user.email}
    rescue
      Ecto.NoResultsError ->
        {:error, "User not found"}
      error ->
        {:error, "Error fetching user: #{inspect(error)}"}
    end
  end

  defp get_user_email(_), do: {:error, "Invalid user ID"}

  defp format_calendar_result({:calendar_created, calendar_job}) do
    "📅 Calendar Event Created: #{calendar_job.event_title}"
  end

  defp format_calendar_result({:calendar_error, _reason}) do
    "❌ Calendar Error"
  end

  defp format_calendar_result({:user_error, _reason}) do
    "👤 User Error"
  end

  defp format_calendar_result({:no_reminder}) do
    "ℹ️ No reminder detected"
  end

  defp format_calendar_result({:no_json}) do
    "ℹ️ Not JSON format"
  end

  defp format_calendar_result({:processing_error, error}) do
    "⚠️ Processing Error: #{inspect(error)}"
  end

  defp format_calendar_result(_) do
    ""
  end
end
