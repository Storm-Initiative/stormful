defmodule Stormful.FlowingThoughts do
  @moduledoc """
  The FlowingThoughts context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo
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
  Returns paginated winds for a sensical with offset support for infinite scroll.
  """
  def list_winds_by_sensical_paginated(sensical_id, user_id, opts \\ []) do
    sort_order = Keyword.get(opts, :sort_order, :desc)
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    query =
      Wind
      |> where([w], w.user_id == ^user_id and w.sensical_id == ^sensical_id)
      |> order_by([w], {^sort_order, w.id})
      |> limit(^limit)
      |> offset(^offset)

    Repo.all(query)
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
    Map.put(attrs, :user_id, user.id)

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
      end

      {:ok, wind}
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

  @doc """
  Returns paginated winds for a journal with offset support for infinite scroll.
  """
  def list_winds_by_journal_paginated(journal_id, user_id, opts \\ []) do
    sort_order = Keyword.get(opts, :sort_order, :desc)
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    query =
      Wind
      |> where([w], w.user_id == ^user_id and w.journal_id == ^journal_id)
      |> order_by([w], {^sort_order, w.id})
      |> limit(^limit)
      |> offset(^offset)

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
