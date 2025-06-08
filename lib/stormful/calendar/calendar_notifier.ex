defmodule Stormful.Calendar.CalendarNotifier do
  @moduledoc """
  Simple calendar event sender via email queue.
  """

  alias Stormful.Queue
  alias Stormful.Calendar.IcalGenerator

  require Logger

  @doc """
  Sends a calendar reminder to user via email.
  """
  def send_reminder_event(user_email, reminder_data, user_id) do
    # Generate iCal content
    ical_content = IcalGenerator.create_reminder_event(reminder_data, user_email)

    # Create simple email
    title = Map.get(reminder_data, "what", "Reminder")
    subject = "📅 Reminder: #{title}"
    body = build_simple_email_body(title, reminder_data)

    # Send via queue
    email_payload = %{
      "to" => user_email,
      "subject" => subject,
      "body" => body,
      "from" => "Stormful <#{StormfulWeb.Endpoint.config(:email_from)}>",
      "attachments" => [
        %{
          "filename" => "reminder.ics",
          "content_type" => "text/calendar",
          "content" => ical_content
        }
      ]
    }

    case Queue.enqueue_email(email_payload, user_id: user_id) do
      {:ok, job} ->
        Logger.info("📅 Queued calendar reminder '#{title}' - Job ID: #{job.id}")
        {:ok, %{job_id: job.id, event_title: title}}

      {:error, reason} ->
        Logger.error("Failed to queue calendar reminder: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp build_simple_email_body(title, reminder_data) do
    location = Map.get(reminder_data, "location", "")
    when_str = Map.get(reminder_data, "when", "")

    location_text = if location != "", do: "\nLocation: #{location}", else: ""
    timing_text = format_when_text(when_str)

    """
    📅 You got a reminder ⚡

    Event: #{title}
    When: #{timing_text}#{location_text}

    With this email, you will receive an ics file. Your calendar app probably already picked it up and scheduled it. But if it didn't, simply click on the attachment to add it to your calendar app!

    Good day to you!

    From the heart,
    Storm Initiative
    """
  end

  defp format_when_text("relative:day:" <> offset_str) do
    case Integer.parse(offset_str) do
      {1, _} -> "Tomorrow"
      {offset, _} when offset > 0 -> "In #{offset} days"
      _ -> "Soon"
    end
  end

  defp format_when_text("relative:minute:" <> offset_str) do
    case Integer.parse(offset_str) do
      {offset, _} when offset > 0 -> "In #{offset} minutes"
      _ -> "Soon"
    end
  end

  defp format_when_text(_), do: "As scheduled"
end
