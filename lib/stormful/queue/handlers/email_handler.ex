defmodule Stormful.Queue.Handlers.EmailHandler do
  @moduledoc """
  Handles email job processing through the queue system.

  This handler manages email delivery jobs, including validation,
  email building, and delivery through the Swoosh mailer system.
  """

  @behaviour Stormful.Queue.JobHandler

  require Logger

  @impl true
  def validate_payload(payload) do
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

  @impl true
  def handle_job(job) do
    Logger.info("Processing email job #{job.id}")

    case validate_payload(job.payload) do
      :ok ->
        send_email(job)

      {:error, reason} ->
        Logger.error("Invalid email payload for job #{job.id}: #{reason}")
        {:error, "Invalid email payload: #{reason}"}
    end
  end

  # Private functions

  defp send_email(job) do
    payload = job.payload

    # Build email struct
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
    try do
      Logger.debug("Building email with subject: #{inspect(email_data.subject)}")

      # Build Swoosh email
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
end
