defmodule Stormful.Queue.Handlers.WebhookHandler do
  @moduledoc """
  Example handler for webhook job processing.

  This demonstrates how easy it is to add new job types to the queue system.
  Simply create a module implementing the JobHandler behavior!

  ## Usage

      # Enqueue a webhook job
      Queue.enqueue_job("webhook", %{
        "url" => "https://api.example.com/webhook",
        "payload" => %{"user_id" => 123, "event" => "signup"},
        "method" => "POST",
        "headers" => %{"Authorization" => "Bearer token123"}
      })

      # That's it! The system automatically discovers and routes to this handler.
  """

  @behaviour Stormful.Queue.JobHandler

  require Logger

  @impl true
  def validate_payload(payload) do
    required_fields = ["url", "payload"]

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
    Logger.info("Processing webhook job #{job.id}")

    case validate_payload(job.payload) do
      :ok ->
        send_webhook(job)

      {:error, reason} ->
        Logger.error("Invalid webhook payload for job #{job.id}: #{reason}")
        {:error, "Invalid webhook payload: #{reason}"}
    end
  end

  # Private functions

  defp send_webhook(job) do
    payload = job.payload

    webhook_request = %{
      url: payload["url"],
      payload: payload["payload"],
      method: Map.get(payload, "method", "POST"),
      headers: Map.get(payload, "headers", %{}),
      timeout: Map.get(payload, "timeout", 30_000)
    }

    case make_http_request(webhook_request) do
      {:ok, response} ->
        Logger.info("Webhook sent successfully for job #{job.id}")
        {:ok, %{
          status_code: response.status_code,
          response_body: response.body,
          sent_at: DateTime.utc_now(),
          webhook_url: webhook_request.url
        }}

      {:error, reason} ->
        Logger.error("Failed to send webhook for job #{job.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp make_http_request(webhook_request) do
    try do
      # Here you would use HTTPoison, Finch, or your preferred HTTP client
      # For demonstration, we'll simulate a webhook call

      Logger.debug("Sending #{webhook_request.method} request to #{webhook_request.url}")
      Logger.debug("Payload: #{inspect(webhook_request.payload)}")

      # Simulate HTTP request delay
      Process.sleep(Enum.random(100..2000))

      # Simulate successful response
      {:ok, %{
        status_code: 200,
        body: Jason.encode!(%{success: true, received_at: DateTime.utc_now()})
      }}
    rescue
      error ->
        {:error, "HTTP request failed: #{inspect(error)}"}
    end
  end
end
