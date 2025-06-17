defmodule Stormful.FlowingThoughts do
  @moduledoc """
  The FlowingThoughts context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo
  alias Stormful.AiRelated.ThoughtExtractionHelper
  require Logger

  alias Stormful.FlowingThoughts.Wind
  @pubsub Stormful.PubSub

  @doc """
  Returns the list of winds. For a sensical, authorized by user_id

  ## Examples

      iex> list_winds_by_sensical(1, 2)
      [%Wind{}, ...]

      iex> list_winds_by_sensical(1, 2, :desc)
      [%Wind{}, ...]

  """
  def list_winds_by_sensical(sensical_id, user_id, sort_order \\ :asc) do
    Wind
    |> where([w], w.user_id == ^user_id and w.sensical_id == ^sensical_id)
    |> order_by([w], {^sort_order, w.id})
    |> Repo.all()
  end

  @doc """
  Gets a single wind.

  Raises `Ecto.NoResultsError` if the Wind does not exist.

  ## Examples

      iex> get_wind!(1, 123)
      %Wind{}

      iex> get_wind!(2, 456)
      ** (Ecto.NoResultsError)

  """
  def get_wind!(user_id, id) do
    Repo.one!(from w in Wind, where: w.user_id == ^user_id and w.id == ^id)
  end

  @doc """
  Creates a wind.

  ## Examples

      iex> create_wind(%{field: value})
      {:ok, %Wind{}}

      iex> create_wind(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_wind(user, attrs \\ %{}) do
    with {:ok, wind} <-
           %Wind{}
           |> Wind.changeset(attrs)
           |> Repo.insert() do
      # Broadcast to appropriate channel based on whether it's for a sensical or journal
      if wind.sensical_id do
        Phoenix.PubSub.broadcast!(@pubsub, topic(wind.sensical_id), {:new_wind, wind})
      end

      if wind.journal_id do
        Phoenix.PubSub.broadcast!(@pubsub, journal_topic(wind.journal_id), {:new_wind, wind})
        maybe_queue_ai_analysis_for_thought(wind, user)
      end

      {:ok, wind}
    end
  end

  defp maybe_queue_ai_analysis_for_thought(wind, user) do
    # Check if user has a profile
    case Stormful.ProfileManagement.get_user_profile(user.id) do
      nil ->
        Logger.info("⏭️  Skipping thought extraction for user #{user.id} - no profile found")
        :skip

      profile ->
        # Check if thought extraction is enabled
        if profile.thought_extraction do
          # Profile exists and thought extraction is enabled, proceed
          perform_thought_extraction(wind, user)
        else
          Logger.info(
            "⏭️  Skipping thought extraction for user #{user.id} - thought extraction disabled in profile"
          )

          :skip
        end
    end
  end

  defp perform_thought_extraction(wind, user) do
    # Create a prompt to analyze the user's thought
    prompt = """
    The JSON structure should be:

    {
      "type": "reminder",
      "what": "the reminder that needs to be done/set-up",
      "when": "a string for the reminder, can be relative or absolute with annotations, like relative:day:+1, absolute:2025-06-08 12:00"
      "the_time_of_the_day_if_day": "the time of the day if the system provides days"
      "location": "the location if the user provides it"
    }

    User generally tells when they need something done by a specific time. We extract date/time in a unique way:
    - User says today -> relative:day:+0
    - User says tomorrow -> relative:day:+1
    - User says in 2 hours -> relative:hour:+2
    - User says in 30 minutes -> relative:minute:+30
    - User says in 2 days -> relative:day:+2
    - User says in 2 weeks -> relative:week:+2
    - User says in 2 months -> relative:month:+2
    - User says in 2 years -> relative:year:+2
    - User says 2025-06-08 -> absolute:2025-06-08
    - User says 2025-06-08 12:00 -> absolute:2025-06-08 12:00
    - User says 2025-06-08 12:00:00 -> absolute:2025-06-08 12:00:00
    - User says 2025-06-08 12:00:00.000 -> absolute:2025-06-08 12:00:00.000
    - User says 2025-06-08 12:00:00.000+03:00 -> absolute:2025-06-08 12:00:00.000
    - User says 2025-06-08 12:00:00.000+03:00 -> absolute:2025-06-08 12:00:00.000

    Beware: if user provides absolute, they might mean in mm/dd/yyyy format, but we need yyyy-mm-dd format. If you ever get confused, leave the field empty:
    - User says 06/08/2025 -> confused_ask:2025-06-08
    - User says 06/08/2025 12:00 -> confused_ask:2025-06-08 12:00
    - User says 06/08/2025 12:00:00 -> confused_ask:2025-06-08 12:00:00
    - User says 06/08/2025 12:00:00.000 -> confused_ask:2025-06-08 12:00:00.000
    - User says 06/08/2025 12:00:00.000+03:00 -> confused_ask:2025-06-08 12:00:00.000
    - User says 06/08/2025 12:00:00.000+03:00 -> confused_ask:2025-06-08 12:00:00.000

    Program will take care of that afterwards, don't worry about it.

    You also might want to provide the_time_of_the_day_if_day, which is the time of the day if the user says a day. You may go logical here, if undecided, leave it null. Should always provide in 24-hour format. But yeah, if user says:
    - I got to go to school tomorrow -> the_time_of_the_day_if_day: 09:00
    - I got to go to school in 2 hours -> the_time_of_the_day_if_day: null
    - I will take a good looking person to dinner tomorrow -> the_time_of_the_day_if_day: 18:00

    User may specify the location too, location is optional, if not provided or not clear, leave it null.
    - I got to go to the dentist tomorrow -> location: null
    - dentist appointment tomorrow at Stonefruit Bakery -> location: "Stonefruit Bakery"

    For example, if the user says "I got to go to the dentist tomorrow", you should respond with:
    {
      "type": "reminder",
      "what": "Go to the dentist",
      "when": "relative:day:+1"
      "the_time_of_the_day_if_day": "09:00"
      "location": null
    }

    Or when user says "remind me today 7:15 pm to close the soup", you should respond with:
    {
      "type": "reminder",
      "what": "close the soup",
      "when": "relative:day:+0"
      "the_time_of_the_day_if_day": "19:15"
      "location": null
    }

    Or when user says "I got a dentist appointment in 2 hours at Stonefruit Bakery", you should respond with:
    {
      "type": "reminder",
      "what": "Go to the dentist",
      "when": "relative:minute:+120"
      "the_time_of_the_day_if_day": null
      "location": "Stonefruit Bakery"
    }


    Please try to respond in the language of the user.

    If user provides a data that is not a reminder, you should respond with null.

    User will provide a thought, and you need to extract if it has a reminder that needs to be done/set-up. Please be mindful of the user's timezone. Also keep in mind about date/time related stuff as I mentioned above, you need to be extra careful with timezone, it is very important for our user's experience. Please only provide the JSON structure, no other text:

    "#{wind.words}"
    """

    # Queue the thought extraction task
    case ThoughtExtractionHelper.complete_async(
           "deepseek/deepseek-chat-v3-0324",
           prompt,
           max_tokens: 150,
           temperature: 0.7,
           user_id: user.id
         ) do
      {:ok, job} ->
        Logger.info(
          "📅 Queued thought extraction for '#{String.slice(wind.words, 0, 50)}...' - Job ID: #{job.id}"
        )

      # Calendar events are now automatically created when the AI detects reminders!
      # The thought extraction worker will:
      # 1. Process the AI response
      # 2. Parse it for calendar events (JSON format)
      # 3. Automatically send calendar invitations via email
      # 4. Log the results in the worker output

      {:error, reason} ->
        Logger.error("Failed to queue thought extraction: #{inspect(reason)}")
    end
  end

  @doc """
  Updates a wind.

  ## Examples

      iex> update_wind(wind, %{field: new_value})
      {:ok, %Wind{}}

      iex> update_wind(wind, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_wind(%Wind{} = wind, attrs) do
    wind
    |> Wind.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a wind.

  ## Examples

      iex> delete_wind(wind)
      {:ok, %Wind{}}

      iex> delete_wind(wind)
      {:error, %Ecto.Changeset{}}

  """
  def delete_wind(%Wind{} = wind) do
    Repo.delete(wind)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking wind changes.

  ## Examples

      iex> change_wind(wind)
      %Ecto.Changeset{data: %Wind{}}

  """
  def change_wind(%Wind{} = wind, attrs \\ %{}) do
    Wind.changeset(wind, attrs)
  end

  def subscribe_to_sensical(sensical) do
    Phoenix.PubSub.subscribe(@pubsub, topic(sensical.id))
  end

  def unsubscribe_from_sensical(sensical) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(sensical.id))
  end

  @doc """
  Returns the list of winds for a journal. Authorized by user_id

  ## Examples

      iex> list_winds_by_journal(1, 2)
      [%Wind{}, ...]

      iex> list_winds_by_journal(1, 2, :desc, 50)
      [%Wind{}, ...]

  """
  def list_winds_by_journal(journal_id, user_id, sort_order \\ :asc, limit \\ nil) do
    query =
      Wind
      |> where([w], w.user_id == ^user_id and w.journal_id == ^journal_id)
      |> order_by([w], {^sort_order, w.id})

    query = if limit, do: limit(query, ^limit), else: query

    Repo.all(query)
  end

  def subscribe_to_journal(journal) do
    Phoenix.PubSub.subscribe(@pubsub, journal_topic(journal.id))
  end

  def unsubscribe_from_journal(journal) do
    Phoenix.PubSub.unsubscribe(@pubsub, journal_topic(journal.id))
  end

  defp topic(sensical_id), do: "sensical_room:#{sensical_id}"
  defp journal_topic(journal_id), do: "journal_room:#{journal_id}"
end
