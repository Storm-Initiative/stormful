defmodule Stormful.Calendar.CalendarNotifier do
  @moduledoc """
  Simple calendar event sender via email queue.
  """

  alias Stormful.Queue
  alias Stormful.Calendar.IcalGenerator
  alias Stormful.AgendaRelated

  require Logger

  @doc """
  Sends a calendar reminder to user via email.
  """
  def send_reminder_event(user_email, reminder_data, user_id) do
    # Check if user has an agenda first
    case check_user_agenda(user_id) do
      {:ok, agenda} ->
        # User has an agenda, add event there
        add_event_to_agenda(agenda, reminder_data, user_id)

      {:error, :no_agenda} ->
        # No agenda, fall back to email
        send_email_reminder(user_email, reminder_data, user_id)
    end
  end

  # Private functions

  defp check_user_agenda(user_id) do
    agendas = AgendaRelated.list_agendas(user_id)

    case agendas do
      [agenda | _] -> {:ok, agenda}
      [] -> {:error, :no_agenda}
    end
  end

  defp add_event_to_agenda(agenda, reminder_data, user_id) do
    title = Map.get(reminder_data, "what", "Reminder")
    when_str = Map.get(reminder_data, "when", "")
    time_of_day = Map.get(reminder_data, "the_time_of_the_day_if_day")

    # Parse the time to get event_date
    utc_now = DateTime.utc_now()

    event_date = case IcalGenerator.parse_when_string(when_str, time_of_day, utc_now) do
      {:ok, time} -> time
      {:error, _} -> DateTime.add(utc_now, 24 * 3600, :second) # fallback to tomorrow
    end

    # Create agenda event
    case AgendaRelated.create_agenda_event(%{
      the_event: title,
      event_date: event_date,
      agenda_id: agenda.id,
      user_id: user_id
    }) do
      {:ok, agenda_event} ->
        Logger.info("📅 Added event to agenda '#{agenda.name}': #{title}")
        {:ok, %{agenda_event_id: agenda_event.id, event_title: title, agenda_name: agenda.name}}

      {:error, changeset} ->
        Logger.error("Failed to add event to agenda: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  defp send_email_reminder(user_email, reminder_data, user_id) do
    # Generate iCal content with timezone adjustment
    ical_content = IcalGenerator.create_reminder_event(reminder_data, user_email, user_id)

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
