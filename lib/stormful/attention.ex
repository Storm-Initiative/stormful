defmodule Stormful.Attention do
  @moduledoc """
  The Attention context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo

  alias Stormful.Attention.Headsup
  @pubsub Stormful.PubSub

  @doc """
  Returns the list of headsups. by sensical id, authorized by user_id

  ## Examples

      iex> list_headsups()
      [%Headsup{}, ...]

  """
  def list_headsups_for_sensical(user_id, sensical_id) do
    Repo.all(from q in Headsup, where: q.user_id == ^user_id and q.sensical_id == ^sensical_id)
  end

  @doc """
  Gets a single headsup.

  Raises `Ecto.NoResultsError` if the Headsup does not exist.

  ## Examples

      iex> get_headsup!(123)
      %Headsup{}

      iex> get_headsup!(456)
      ** (Ecto.NoResultsError)

  """
  def get_headsup!(id), do: Repo.get!(Headsup, id)

  @doc """
  Creates a headsup. with userid and sensical id

  ## Examples

      iex> create_headsup(1,2,"hey")
      {:ok, %Headsup{}}

      iex> create_headsup(1,2,"nay")
      {:error, %Ecto.Changeset{}}

  """
  def create_headsup(user_id, sensical_id, title) do
    with {:ok, headsup} <-
           %Headsup{}
           |> Headsup.changeset(%{user_id: user_id, sensical_id: sensical_id, title: title})
           |> Repo.insert() do
      Phoenix.PubSub.broadcast!(@pubsub, topic(headsup.sensical_id), {:new_headsup, headsup})
      {:ok, headsup}
    end
  end

  @doc """
  Updates a headsup.

  ## Examples

      iex> update_headsup(headsup, %{field: new_value})
      {:ok, %Headsup{}}

      iex> update_headsup(headsup, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_headsup(%Headsup{} = headsup, attrs) do
    headsup
    |> Headsup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a headsup.

  ## Examples

      iex> delete_headsup(headsup)
      {:ok, %Headsup{}}

      iex> delete_headsup(headsup)
      {:error, %Ecto.Changeset{}}

  """
  def delete_headsup(%Headsup{} = headsup) do
    Repo.delete(headsup)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking headsup changes.

  ## Examples

      iex> change_headsup(headsup)
      %Ecto.Changeset{data: %Headsup{}}

  """
  def change_headsup(%Headsup{} = headsup, attrs \\ %{}) do
    Headsup.changeset(headsup, attrs)
  end

  def subscribe_to_sensical(sensical) do
    Phoenix.PubSub.subscribe(@pubsub, topic(sensical.id))
  end

  def unsubscribe_from_sensical(sensical) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(sensical.id))
  end

  defp topic(sensical_id), do: "sensical_attentioooons:#{sensical_id}"
end
