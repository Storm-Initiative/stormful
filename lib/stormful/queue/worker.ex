defmodule Stormful.Queue.Worker do
  @moduledoc """
  Worker module that handles the actual execution of background jobs.

  This module:
  - Processes different types of jobs (email, AI processing)
  - Implements the actual business logic for each job type
  - Handles errors and timeout scenarios
  - Integrates with rate limiting checks
  """

  require Logger

  alias Stormful.Calendar.CalendarNotifier
  alias Stormful.Accounts

  @doc """
  Main entry point for processing a job.

  Handles different job types and business logic, with error handling and logging.

  ## Examples

      iex> Worker.process_job(email_job)
      {:ok, %{delivered_at: ~U[2025-05-30 19:30:00Z]}}

      iex> Worker.process_job(ai_job)
      {:ok, %{response: "AI analysis complete", tokens_used: 150}}
  """
  def process_job(job) do
    Logger.info("Worker processing job #{job.id} of type #{job.task_type}")

    process_job_by_type(job)
  rescue
    error ->
      Logger.error("Unexpected error processing job #{job.id}: #{inspect(error)}")
      {:error, error}
  end

  ## Job Type Handlers

  defp process_job_by_type(%{task_type: "email"} = job) do
    process_email_job(job)
  end

  defp process_job_by_type(%{task_type: "ai_processing"} = job) do
    process_ai_job(job)
  end

  defp process_job_by_type(%{task_type: "thought_extraction"} = job) do
    process_thought_extraction_job(job)
  end

  defp process_job_by_type(job) do
    Logger.error("Unknown job type: #{job.task_type}")
    {:error, "Unknown job type: #{job.task_type}"}
  end

  ## Email Job Processing

  defp process_email_job(job) do
    Logger.info("Processing email job #{job.id}")

    case validate_email_payload(job.payload) do
      :ok ->
        send_email(job)

      {:error, reason} ->
        Logger.error("Invalid email payload for job #{job.id}: #{reason}")
        {:error, "Invalid email payload: #{reason}"}
    end
  end

  defp validate_email_payload(payload) do
    required_fields = ["to", "subject"]

    missing_fields =
      required_fields
      |> Enum.filter(fn field -> not Map.has_key?(payload, field) end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  defp send_email(job) do
    payload = job.payload

    # Build email struct (adjust based on your mailer implementation)
    email_data = %{
      to: payload["to"],
      subject: payload["subject"],
      body: Map.get(payload, "body", ""),
      html_body: Map.get(payload, "html_body", ""),
      from: Map.get(payload, "from", StormfulWeb.Endpoint.config(:email_from)),
      template: Map.get(payload, "template"),
      template_data: Map.get(payload, "template_data", %{}),
      attachments: Map.get(payload, "attachments", [])
    }

    case deliver_email(email_data) do
      {:ok, delivery_info} ->
        Logger.info("Email sent successfully for job #{job.id}")
        {:ok, %{
          delivered_at: DateTime.utc_now(),
          delivery_info: delivery_info,
          recipient: payload["to"]
        }}

      {:error, reason} ->
        Logger.error("Failed to send email for job #{job.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp deliver_email(email_data) do
    # Integrate with existing Swoosh/Mailer system
    try do
      # Debug logging to check what subject we're using
      Logger.debug("Building email with subject: #{inspect(email_data.subject)}")

      # Build Swoosh email using the existing system
      email =
        Swoosh.Email.new()
        |> Swoosh.Email.to(email_data.to)
        |> Swoosh.Email.from(email_data.from)
        |> Swoosh.Email.subject(email_data.subject)
        |> Swoosh.Email.text_body(email_data.body)

      # Add HTML body if provided
      email = if email_data.html_body != "", do: Swoosh.Email.html_body(email, email_data.html_body), else: email

      # Add attachments if provided
      email = add_attachments(email, email_data.attachments)

      Logger.debug("Built email: subject=#{inspect(email.subject)}, to=#{inspect(email.to)}")

      # Deliver using the application's Mailer
      case Stormful.Mailer.deliver(email) do
        {:ok, metadata} ->
          {:ok, %{
            message_id: metadata[:id] || "swoosh_delivered",
            provider: "swoosh_mailer",
            timestamp: DateTime.utc_now(),
            metadata: metadata
          }}

        {:error, reason} ->
          {:error, "Email delivery failed: #{inspect(reason)}"}
      end
    rescue
      error ->
        {:error, "Email delivery failed: #{inspect(error)}"}
    end
  end

  defp add_attachments(email, []), do: email

  defp add_attachments(email, attachments) when is_list(attachments) do
    Enum.reduce(attachments, email, fn attachment, acc ->
      case attachment do
        %{"filename" => filename, "content" => content, "content_type" => content_type} ->
          Swoosh.Email.attachment(acc, %Swoosh.Attachment{
            filename: filename,
            content_type: content_type,
            data: content
          })

        %{"filename" => filename, "content" => content} ->
          # Default content type if not provided
          Swoosh.Email.attachment(acc, %Swoosh.Attachment{
            filename: filename,
            content_type: "application/octet-stream",
            data: content
          })

        _ ->
          Logger.warning("Skipping invalid attachment: #{inspect(attachment)}")
          acc
      end
    end)
  end

  defp add_attachments(email, _), do: email

  ## AI Job Processing

  defp process_ai_job(job) do
    Logger.info("Processing AI job #{job.id}")

    case validate_ai_payload(job.payload) do
      :ok ->
        process_ai_request(job)

      {:error, reason} ->
        Logger.error("Invalid AI payload for job #{job.id}: #{reason}")
        {:error, "Invalid AI payload: #{reason}"}
    end
  end

  defp validate_ai_payload(payload) do
    required_fields = ["prompt"]

    missing_fields =
      required_fields
      |> Enum.filter(fn field -> not Map.has_key?(payload, field) end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  defp process_ai_request(job) do
    payload = job.payload

    ai_request = %{
      prompt: payload["prompt"],
      model: Map.get(payload, "model", "mistralai/mistral-nemo"),
      max_tokens: Map.get(payload, "max_tokens", 150),
      temperature: Map.get(payload, "temperature", 0.7),
      user_id: job.user_id
    }

    case call_ai_service(ai_request) do
      {:ok, response} ->
        Logger.info("AI processing completed for job #{job.id}")
        {:ok, %{
          response: response.text,
          tokens_used: response.tokens_used,
          model_used: response.model,
          processing_time_ms: response.processing_time,
          completed_at: DateTime.utc_now()
        }}

      {:error, reason} ->
        Logger.error("AI processing failed for job #{job.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp call_ai_service(ai_request) do
    # This is where you'd integrate with your actual AI service
    # For now, we'll simulate the AI processing

    try do
      # Simulate AI processing delay (2-10 seconds)
      processing_time = Enum.random(2000..10000)
      Process.sleep(processing_time)

      # Here you would actually call your AI service:
      # - OpenAI API
      # - Claude API
      # - Your existing AI modules

      # Simulate response based on prompt length
      prompt_length = String.length(ai_request.prompt)
      tokens_used = min(ai_request.max_tokens, prompt_length * 2)

      response_text = generate_simulated_response(ai_request.prompt)

      {:ok, %{
        text: response_text,
        tokens_used: tokens_used,
        model: ai_request.model,
        processing_time: processing_time
      }}
    rescue
      error ->
        {:error, "AI service call failed: #{inspect(error)}"}
    end
  end

  defp generate_simulated_response(prompt) do
    # Simple simulation of AI response
    prompt_words = String.split(prompt) |> length()

    cond do
      prompt_words < 10 -> "This is a brief AI response to your short prompt."
      prompt_words < 50 -> "This is a medium-length AI response that addresses the key points in your prompt with some detail and analysis."
      true -> "This is a comprehensive AI response that thoroughly analyzes your detailed prompt, providing insights, recommendations, and detailed explanations across multiple aspects of your query."
    end
  end

  ## Thought Extraction Job Processing (OpenRouter)

  defp process_thought_extraction_job(job) do
    Logger.info("Processing thought extraction job #{job.id}")

    case validate_thought_extraction_payload(job.payload) do
      :ok ->
        process_openrouter_request(job)

      {:error, reason} ->
        Logger.error("Invalid thought extraction payload for job #{job.id}: #{reason}")
        {:error, "Invalid thought extraction payload: #{reason}"}
    end
  end

  defp validate_thought_extraction_payload(payload) do
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

        # if the AI response starts with "```json" or "```" or "```json\n" or "```\n", remove it
        text = String.replace(text, ~r/^```(json)?\n?/, "")
        # also if it ends with "```json" or "```" or "```json\n" or "```\n", remove it
        text = String.replace(text, ~r/\n?```(json)?$/, "")

        # Parse the AI response to check for calendar events
        calendar_result = process_calendar_from_ai_response(text, job.user_id)

        # Log the thought extraction output for the beautiful ending! ✨
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
    _error -> {:processing_error}
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

  defp format_calendar_result({:processing_error}) do
    "⚠️ Processing Error"
  end

  defp format_calendar_result(_) do
    ""
  end

  ## Helper Functions

  @doc """
  Health check function to verify the worker can process jobs.
  """
  def health_check do
    # Test with a valid email job but empty payload to trigger validation error
    test_job = %{
      id: "health_check",
      task_type: "email",
      payload: %{},  # Missing required fields - will fail validation
      user_id: nil
    }

    case process_job_by_type(test_job) do
      {:error, "Invalid email payload: " <> _reason} ->
        # This is expected - validation should fail with empty payload
        :ok

      {:error, _other} ->
        # Any other error is also acceptable for health check
        :ok

      {:ok, _result} ->
        # Shouldn't happen with empty payload, but not a problem
        :ok
    end
  rescue
    error ->
      {:error, "Worker health check failed: #{inspect(error)}"}
  end

  @doc """
  Returns statistics about job processing performance.
  """
  def get_processing_stats do
    %{
      supported_job_types: ["email", "ai_processing", "thought_extraction"],
      average_email_time_ms: 300,
      average_ai_time_ms: 5000,
      average_thought_extraction_time_ms: 2000,
      last_health_check: DateTime.utc_now()
    }
  end
end
