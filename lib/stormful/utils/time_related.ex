defmodule Stormful.Utils.TimeRelated do
  def fix_date_for_timezone(datetime_obj, user_timezone, reverse_for_display \\ false) do
    if reverse_for_display do
      tz = Timex.Timezone.get(user_timezone)
      offset_from_utc_in_seconds_signed_int = tz.offset_utc

      # if reverse_for_display, we turn it around, hence we actually add back the hours we removed.
      # and a bonus -> user's timezone may change over time, by doing this we show em absolute time
      # good stuff

      datetime_obj |> NaiveDateTime.shift(second: offset_from_utc_in_seconds_signed_int)
    else
      {res, naive_datetime} = NaiveDateTime.from_iso8601("#{datetime_obj}:00")

      if res == :ok and Timex.is_valid_timezone?(user_timezone) do
        tz = Timex.Timezone.get(user_timezone)
        offset_from_utc_in_seconds_signed_int = tz.offset_utc
        offset_seconds_reversed_for_database = offset_from_utc_in_seconds_signed_int * -1

        naive_datetime |> NaiveDateTime.shift(second: offset_seconds_reversed_for_database)
      else
        datetime_obj
      end
    end
  end
end
