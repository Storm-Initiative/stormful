defmodule Stormful.FlowingThoughts do
  @moduledoc """
  The FlowingThoughts context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo

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
  def create_wind(attrs \\ %{}) do
    with {:ok, wind} <-
           %Wind{}
           |> Wind.changeset(attrs)
           |> Repo.insert() do
      Phoenix.PubSub.broadcast!(@pubsub, topic(wind.sensical_id), {:new_wind, wind})
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

  defp topic(sensical_id), do: "sensical_room:#{sensical_id}"
end
