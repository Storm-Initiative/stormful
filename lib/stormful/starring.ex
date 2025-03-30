defmodule Stormful.Starring do
  @moduledoc """
  The Starring context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo

  alias Stormful.Starring.StarredSensical

  @doc """
  Returns the list of starred_sensicals. Namespaced/authenticated by user_id

  ## Examples

      iex> list_starred_sensicals(1)
      [%StarredSensical{}, ...]

  """
  def list_starred_sensicals(user_id) do
    Repo.all(
      from s in StarredSensical,
        where: s.user_id == ^user_id,
        order_by: [desc: s.inserted_at],
        preload: [:sensical]
    )
  end

  @doc """
  Gets a single starred_sensical.

  Raises `Ecto.NoResultsError` if the Starred sensical does not exist.

  ## Examples

      iex> get_starred_sensical!(1, 123)
      %StarredSensical{}

      iex> get_starred_sensical!(2, 456)
      ** (Ecto.NoResultsError)

  """
  def get_starred_sensical!(user_id, id) do
    Repo.one!(from s in StarredSensical, where: s.user_id == ^user_id and s.sensical_id == ^id)
  end

  @doc """
  Gets a single starred_sensical.

  Gives nil if the Starred sensical does not exist.

  ## Examples

      iex> get_starred_sensical(1, 123)
      %StarredSensical{}

      iex> get_starred_sensical!(2, 456)
      nil

  """
  def get_starred_sensical(user_id, id) do
    Repo.one(from s in StarredSensical, where: s.user_id == ^user_id and s.sensical_id == ^id)
  end

  @doc """
  Creates a starred_sensical.

  ## Examples

      iex> create_starred_sensical(%{field: value})
      {:ok, %StarredSensical{}}

      iex> create_starred_sensical(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_starred_sensical(attrs \\ %{}) do
    %StarredSensical{}
    |> StarredSensical.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a starred_sensical.

  ## Examples

      iex> update_starred_sensical(starred_sensical, %{field: new_value})
      {:ok, %StarredSensical{}}

      iex> update_starred_sensical(starred_sensical, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_starred_sensical(%StarredSensical{} = starred_sensical, attrs) do
    starred_sensical
    |> StarredSensical.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a starred_sensical.

  ## Examples

      iex> delete_starred_sensical(starred_sensical)
      {:ok, %StarredSensical{}}

      iex> delete_starred_sensical(starred_sensical)
      {:error, %Ecto.Changeset{}}

  """
  def delete_starred_sensical(%StarredSensical{} = starred_sensical) do
    Repo.delete(starred_sensical)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking starred_sensical changes.

  ## Examples

      iex> change_starred_sensical(starred_sensical)
      %Ecto.Changeset{data: %StarredSensical{}}

  """
  def change_starred_sensical(%StarredSensical{} = starred_sensical, attrs \\ %{}) do
    StarredSensical.changeset(starred_sensical, attrs)
  end

  @doc """
  Stars a sensicality for the user

  ## Examples

      iex> star_the_sensical(1, 2)
      {:ok, %StarredSensical{}}

      iex> star_the_sensical(3, 4)
      {:error, %Ecto.Changeset{}}

  """
  def star_the_sensical(user_id, sensical_id) do
    create_starred_sensical(%{user_id: user_id, sensical_id: sensical_id})
  end

  @doc """
  Unstars a sensicality for the user

  ## Examples

      iex> unstar_the_sensical(1, 2)
      {:ok, %StarredSensical{}}

      iex> unstar_the_sensical(3, 4)
      {:error, %Ecto.Changeset{}}

  """
  def unstar_the_sensical(user_id, sensical_id) do
    sensical = get_starred_sensical!(user_id, sensical_id)
    delete_starred_sensical(sensical)
  end
end
