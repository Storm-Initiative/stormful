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
    # Quick pre-filter to check if text might contain reminders
    case quick_reminder_check(wind.words) do
      false ->
        Logger.info("⏭️  Skipping detailed extraction - no reminder indicators found")
        :skip

      true ->
        Logger.info("🔍 Reminder indicators found, proceeding with detailed extraction")
        perform_detailed_extraction(wind, user)
    end
  end

  defp quick_reminder_check(text) do
    # Simple keyword-based check to avoid expensive AI calls
    reminder_keywords = [
      # Direct reminders
      "remind",
      "reminder",
      "schedule",
      "appointment",
      "meeting",
      "deadline",
      # Time indicators
      "tomorrow",
      "today",
      "tonight",
      "later",
      "next week",
      "next month",
      "at",
      "on",
      "by",
      "before",
      "after",
      "in",
      "minutes",
      "hours",
      "days",
      # Action words
      "call",
      "email",
      "visit",
      "go to",
      "pick up",
      "drop off",
      "buy",
      "get",
      # Obligation words
      "don't forget",
      "remember",
      "need to",
      "have to",
      "must",
      "should",
      # Casual/slang obligations
      "gotta",
      "gonna",
      "wanna",
      "lemme",
      "i'll",
      "ill",
      "i will",
      "i need",
      "we gotta",
      "we need",
      "we should",
      "im gonna",
      "i'm gonna",
      "i gotta",
      "i'm going to",
      "im going to",
      "i'll go",
      "ill go",
      "i'll do",
      "ill do",
      # Programmer/work speak
      "fix",
      "debug",
      "deploy",
      "push",
      "commit",
      "refactor",
      "test",
      "ship",
      "merge",
      "review",
      "update",
      "patch",
      "hotfix",
      "release"
    ]

    text_lower = String.downcase(text)

    Enum.any?(reminder_keywords, fn keyword ->
      String.contains?(text_lower, keyword)
    end)
  end

  defp perform_detailed_extraction(wind, user) do
    # Create a prompt to analyze the user's thought
    prompt = """
    Extract reminder from text. Return JSON or null if no reminder.

    Format:
    {
      "type": "reminder",
      "what": "task description",
      "when": "time format",
      "the_time_of_the_day_if_day": "HH:MM or null",
      "location": "location or null"
    }

    Time formats:
    - today/tomorrow → relative:day:+0/+1
    - in X hours/minutes → relative:hour:+X / relative:minute:+X
    - in X days/weeks → relative:day:+X / relative:week:+X
    - specific date → absolute:YYYY-MM-DD

    Text: "#{wind.words}"
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
