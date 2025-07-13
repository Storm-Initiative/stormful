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

          # Only apply timezone conversion for absolute dates, not relative times
          if String.starts_with?(when_str, "absolute:") do
            # Get user timezone and convert properly
            user_timezone = Stormful.ProfileManagement.get_user_timezone(user_id)

            case convert_to_user_timezone(time, user_timezone) do
              {:ok, converted_time} ->
                Logger.info("🗓️  Converted to user timezone #{user_timezone}: #{converted_time}")
                converted_time |> DateTime.truncate(:second)

              {:error, reason} ->
                Logger.warning("🗓️  Timezone conversion failed (#{reason}), using original time")
                time |> DateTime.truncate(:second)
            end
          else
            # For relative times, no timezone conversion needed
            Logger.info("🗓️  Relative time, no timezone conversion needed")
            time |> DateTime.truncate(:second)
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

  defp parse_when_string("absolute:" <> datetime_str, time_of_day, _time_of_interest) do
    Logger.info("🗓️  Parsing absolute datetime: #{datetime_str}")

    case parse_absolute_datetime(datetime_str) do
      {:ok, datetime} ->
        Logger.info("🗓️  Successfully parsed absolute datetime: #{datetime}")
        apply_time_of_day(datetime, time_of_day)

      {:error, reason} ->
        Logger.warning("🗓️  Failed to parse absolute datetime '#{datetime_str}': #{reason}")
        {:error, reason}
    end
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

  defp parse_absolute_datetime(datetime_str) do
    # Handle various absolute datetime formats
    case datetime_str do
      # ISO 8601 formats
      dt when byte_size(dt) >= 19 ->
        case DateTime.from_iso8601(
               dt <>
                 if(
                   String.contains?(dt, "Z") or String.contains?(dt, "+") or
                     String.contains?(dt, "-"),
                   do: "",
                   else: "Z"
                 )
             ) do
          {:ok, datetime, _} -> {:ok, datetime}
          {:error, _} -> try_parse_naive_datetime(dt)
        end

      # Date only (YYYY-MM-DD)
      dt when byte_size(dt) == 10 ->
        case Date.from_iso8601(dt) do
          {:ok, date} ->
            # Convert to datetime at midnight UTC
            {:ok, DateTime.new!(date, ~T[00:00:00], "Etc/UTC")}

          {:error, _} ->
            try_parse_alternative_formats(dt)
        end

      # Short formats
      _ ->
        try_parse_alternative_formats(datetime_str)
    end
  end

  defp try_parse_naive_datetime(dt_str) do
    # Try parsing as naive datetime and convert to UTC
    case NaiveDateTime.from_iso8601(dt_str) do
      {:ok, naive_dt} ->
        {:ok, DateTime.from_naive!(naive_dt, "Etc/UTC")}

      {:error, _} ->
        try_parse_alternative_formats(dt_str)
    end
  end

  defp try_parse_alternative_formats(dt_str) do
    # Handle common formats like MM/DD/YYYY, DD/MM/YYYY, etc.
    cond do
      # MM/DD/YYYY or MM/DD/YYYY HH:MM
      Regex.match?(~r/^\d{1,2}\/\d{1,2}\/\d{4}/, dt_str) ->
        parse_slash_format(dt_str)

      # DD-MM-YYYY or similar
      Regex.match?(~r/^\d{1,2}-\d{1,2}-\d{4}/, dt_str) ->
        parse_dash_format(dt_str)

      # YYYY/MM/DD
      Regex.match?(~r/^\d{4}\/\d{1,2}\/\d{1,2}/, dt_str) ->
        parse_iso_like_format(dt_str)

      true ->
        {:error, "Unrecognized datetime format: #{dt_str}"}
    end
  end

  defp parse_slash_format(dt_str) do
    # Parse MM/DD/YYYY or MM/DD/YYYY HH:MM
    case String.split(dt_str, " ", parts: 2) do
      [date_part, time_part] ->
        with {:ok, date} <- parse_mdy_date(date_part),
             {:ok, time} <- parse_time(time_part) do
          {:ok, DateTime.new!(date, time, "Etc/UTC")}
        end

      [date_part] ->
        case parse_mdy_date(date_part) do
          {:ok, date} ->
            {:ok, DateTime.new!(date, ~T[00:00:00], "Etc/UTC")}

          error ->
            error
        end
    end
  end

  defp parse_dash_format(dt_str) do
    # Similar to slash format but with dashes
    dt_str
    |> String.replace("-", "/")
    |> parse_slash_format()
  end

  defp parse_iso_like_format(dt_str) do
    # Convert YYYY/MM/DD to YYYY-MM-DD and parse
    iso_str = String.replace(dt_str, "/", "-")
    parse_absolute_datetime(iso_str)
  end

  defp parse_mdy_date(date_str) do
    # Parse MM/DD/YYYY format
    case String.split(date_str, "/") do
      [month_str, day_str, year_str] ->
        with {month, _} <- Integer.parse(month_str),
             {day, _} <- Integer.parse(day_str),
             {year, _} <- Integer.parse(year_str),
             {:ok, date} <- Date.new(year, month, day) do
          {:ok, date}
        else
          _ -> {:error, "Invalid date format: #{date_str}"}
        end

      _ ->
        {:error, "Invalid date format: #{date_str}"}
    end
  end

  defp parse_time(time_str) do
    # Parse HH:MM or HH:MM:SS format
    case String.split(time_str, ":") do
      [hour_str, minute_str] ->
        with {hour, _} <- Integer.parse(hour_str),
             {minute, _} <- Integer.parse(minute_str),
             {:ok, time} <- Time.new(hour, minute, 0) do
          {:ok, time}
        else
          _ -> {:error, "Invalid time format: #{time_str}"}
        end

      [hour_str, minute_str, second_str] ->
        with {hour, _} <- Integer.parse(hour_str),
             {minute, _} <- Integer.parse(minute_str),
             {second, _} <- Integer.parse(second_str),
             {:ok, time} <- Time.new(hour, minute, second) do
          {:ok, time}
        else
          _ -> {:error, "Invalid time format: #{time_str}"}
        end

      _ ->
        {:error, "Invalid time format: #{time_str}"}
    end
  end

  defp convert_to_user_timezone(datetime, user_timezone) do
    case user_timezone do
      nil ->
        {:ok, datetime}

      "UTC" ->
        {:ok, datetime}

      timezone_name ->
        try do
          # Convert FROM UTC TO user timezone for interpretation, then back to UTC
          # User says 11am in their timezone, we need to interpret the time as local time
          naive_datetime = DateTime.to_naive(datetime)
          user_datetime = Timex.to_datetime(naive_datetime, timezone_name)
          utc_datetime = Timex.Timezone.convert(user_datetime, "UTC")
          {:ok, utc_datetime}
        rescue
          _ ->
            {:error, "Invalid timezone: #{timezone_name}"}
        end
    end
  end
end
