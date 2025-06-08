defmodule Stormful.Calendar.IcalGenerator do
  @moduledoc """
  Simple iCal (.ics) file generator for calendar events.
  """

  @doc """
  Creates a basic iCal string for a calendar event.

  ## Required options
  * `:title` - Event title
  * `:start_time` - DateTime for event start
  * `:user_email` - User's email address
  """
  def create_event(opts) do
    title = Keyword.fetch!(opts, :title)
    start_time = Keyword.fetch!(opts, :start_time)
    user_email = Keyword.fetch!(opts, :user_email)

    end_time = Keyword.get(opts, :end_time, DateTime.add(start_time, 3600, :second))
    location = Keyword.get(opts, :location, "")

    uid = "stormful-#{System.system_time(:millisecond)}-#{:rand.uniform(10000)}"
    now = DateTime.utc_now()

    """
    BEGIN:VCALENDAR\r
    VERSION:2.0\r
    PRODID:-//Stormful//Calendar//EN\r
    BEGIN:VEVENT\r
    UID:#{uid}\r
    DTSTAMP:#{format_datetime(now)}\r
    DTSTART:#{format_datetime(start_time)}\r
    DTEND:#{format_datetime(end_time)}\r
    SUMMARY:#{escape_text(title)}\r
    LOCATION:#{escape_text(location)}\r
    ATTENDEE:MAILTO:#{user_email}\r
    END:VEVENT\r
    END:VCALENDAR\r
    """
  end

  @doc """
  Creates event from AI reminder data.
  """
  def create_reminder_event(reminder_data, user_email) do
    title = Map.get(reminder_data, "what", "Reminder")
    location = Map.get(reminder_data, "location", "")
    when_str = Map.get(reminder_data, "when", "")
    time_of_day = Map.get(reminder_data, "the_time_of_the_day_if_day")

    start_time = case parse_when_string(when_str, time_of_day) do
      {:ok, time} -> time
      {:error, _} -> DateTime.add(DateTime.utc_now(), 24 * 3600, :second)  # Default to tomorrow
    end

    create_event(
      title: title,
      start_time: start_time,
      location: location,
      user_email: user_email
    )
  end

  # Private functions

  defp format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.to_naive()
    |> NaiveDateTime.to_iso8601(:basic)
    |> String.replace("-", "")
    |> String.replace(":", "")
    |> Kernel.<>("Z")
  end

  defp escape_text(text) when is_binary(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(",", "\\,")
    |> String.replace(";", "\\;")
    |> String.replace("\n", "\\n")
  end
  defp escape_text(_), do: ""

  defp parse_when_string("relative:day:" <> offset_str, time_of_day) do
    case Integer.parse(offset_str) do
      {offset, _} ->
        base_time = DateTime.add(DateTime.utc_now(), offset * 24 * 3600, :second)
        apply_time_of_day(base_time, time_of_day)
      :error -> {:error, "Invalid day offset"}
    end
  end

  defp parse_when_string("relative:minute:" <> offset_str, _) do
    case Integer.parse(offset_str) do
      {offset, _} -> {:ok, DateTime.add(DateTime.utc_now(), offset * 60, :second)}
      :error -> {:error, "Invalid minute offset"}
    end
  end

  defp parse_when_string(_, _), do: {:error, "Unknown when format"}

  defp apply_time_of_day(datetime, nil), do: {:ok, datetime}
  defp apply_time_of_day(datetime, time_string) when is_binary(time_string) do
    case Time.from_iso8601(time_string <> ":00") do
      {:ok, time} ->
        new_datetime = %{datetime | hour: time.hour, minute: time.minute, second: 0, microsecond: {0, 0}}
        {:ok, new_datetime}
      {:error, _} -> {:ok, datetime}
    end
  end
  defp apply_time_of_day(datetime, _), do: {:ok, datetime}
end
