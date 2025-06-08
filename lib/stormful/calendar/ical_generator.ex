defmodule Stormful.Calendar.IcalGenerator do
  @moduledoc """
  Simple iCal (.ics) file generator for calendar events.
  Uses Timex for robust timezone and date/time handling.
  """

  require Logger

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
  def create_reminder_event(reminder_data, user_email, user_id) do
    title = Map.get(reminder_data, "what", "Reminder")
    location = Map.get(reminder_data, "location", "")
    when_str = Map.get(reminder_data, "when", "")
    time_of_day = Map.get(reminder_data, "the_time_of_the_day_if_day")

    # Calculate user's local datetime once
    utc_now = DateTime.utc_now()

    start_time =
      case parse_when_string(when_str, time_of_day, utc_now) do
        {:ok, time} ->
          Logger.info("🗓️  Successfully parsed time: #{time}")
          user_timezone = Stormful.ProfileManagement.get_user_timezone(user_id)
          amount_of_hours_to_add = Timex.timezone(user_timezone, DateTime.utc_now()).abbreviation
          Logger.info("🗓️  Amount of hours to add: #{amount_of_hours_to_add}")

          if time_of_day do
            time =
              DateTime.add(time, String.to_integer(amount_of_hours_to_add) * -3600, :second)
              |> DateTime.truncate(:second)

            Logger.info("🗓️  Time after adding hours: #{time}")
            time
          else
            time = time |> DateTime.truncate(:second)
            Logger.info("🗓️  Time after adding hours: #{time}")
            time
          end

        {:error, reason} ->
          Logger.warning("🗓️  Failed to parse time (#{reason}), defaulting to tomorrow UTC")
          # Simple fallback
          DateTime.add(DateTime.utc_now(), 24 * 3600, :second)
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

  defp parse_when_string("relative:day:" <> offset_str, time_of_day, time_of_interest) do
    case Integer.parse(offset_str) do
      {offset, _} ->
        # Add the day offset to user's local time
        target_date = DateTime.add(time_of_interest, offset * 24 * 3600, :second)

        apply_time_of_day(target_date, time_of_day)

      :error ->
        Logger.error("🗓️  Invalid day offset: #{offset_str}")
        {:error, "Invalid day offset"}
    end
  end

  defp parse_when_string("relative:minute:" <> offset_str, _, time_of_interest) do
    case Integer.parse(offset_str) do
      {offset, _} ->
        # Add minute offset to user's local time
        result = DateTime.add(time_of_interest, offset * 60, :second)
        {:ok, result}

      :error ->
        Logger.error("🗓️  Invalid minute offset: #{offset_str}")
        {:error, "Invalid minute offset"}
    end
  end

  defp parse_when_string("relative:hour:" <> offset_str, _, time_of_interest) do
    case Integer.parse(offset_str) do
      {offset, _} ->
        # Add hour offset to user's local time
        result = DateTime.add(time_of_interest, offset * 3600, :second)
        {:ok, result}

      :error ->
        Logger.error("🗓️  Invalid hour offset: #{offset_str}")
        {:error, "Invalid hour offset"}
    end
  end

  defp parse_when_string("relative:week:" <> offset_str, time_of_day, time_of_interest) do
    case Integer.parse(offset_str) do
      {offset, _} ->
        target_date = DateTime.add(time_of_interest, offset * 7 * 24 * 3600, :second)
        apply_time_of_day(target_date, time_of_day)

      :error ->
        Logger.error("🗓️  Invalid week offset: #{offset_str}")
        {:error, "Invalid week offset"}
    end
  end

  defp parse_when_string("relative:month:" <> offset_str, time_of_day, time_of_interest) do
    case Integer.parse(offset_str) do
      {offset, _} ->
        # Approximate months as 30 days for simplicity
        target_date = DateTime.add(time_of_interest, offset * 30 * 24 * 3600, :second)
        apply_time_of_day(target_date, time_of_day)

      :error ->
        Logger.error("🗓️  Invalid month offset: #{offset_str}")
        {:error, "Invalid month offset"}
    end
  end

  # Keep absolute parsing simple for now
  defp parse_when_string("absolute:" <> _datetime_str, _, _time_of_interest) do
    Logger.info("🗓️  Absolute datetime parsing not implemented yet, using fallback")
    {:error, "Absolute datetime parsing not implemented"}
  end

  defp parse_when_string(_, _, _), do: {:error, "Unknown when format"}

  defp apply_time_of_day(datetime, nil) do
    Logger.info("🗓️  No specific time of day provided, keeping: #{datetime}")
    {:ok, datetime}
  end

  defp apply_time_of_day(datetime, time_string) when is_binary(time_string) do
    # Simple time parsing - just handle HH:MM format for now
    case String.split(time_string, ":") do
      [hour_str, minute_str] ->
        case {Integer.parse(hour_str), Integer.parse(minute_str)} do
          {{hour, _}, {minute, _}}
          when hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 ->
            # Calculate the time difference and adjust datetime
            current_hour = datetime.hour
            current_minute = datetime.minute

            # Calculate total minutes difference
            target_minutes = hour * 60 + minute
            current_minutes = current_hour * 60 + current_minute
            minute_diff = target_minutes - current_minutes

            # Apply the difference
            new_datetime = DateTime.add(datetime, minute_diff * 60, :second)
            Logger.info("🗓️  Set time to #{time_string}, result: #{new_datetime}")
            {:ok, new_datetime}

          _ ->
            Logger.warning(
              "🗓️  Invalid hour/minute values in '#{time_string}', keeping original time"
            )

            {:ok, datetime}
        end

      _ ->
        Logger.warning("🗓️  Could not parse time format '#{time_string}', keeping original time")
        {:ok, datetime}
    end
  end

  defp apply_time_of_day(datetime, other) do
    Logger.info("🗓️  Non-string time value #{inspect(other)}, keeping: #{datetime}")
    {:ok, datetime}
  end
end
