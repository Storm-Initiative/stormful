defmodule Stormful.Attention do
  @moduledoc """
  The Attention context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo

  alias Stormful.Attention.Headsup

  @doc """
  Returns the list of headsups.

  ## Examples

      iex> list_headsups()
      [%Headsup{}, ...]

  """
  def list_headsups do
    Repo.all(Headsup)
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
  Creates a headsup.

  ## Examples

      iex> create_headsup(%{field: value})
      {:ok, %Headsup{}}

      iex> create_headsup(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_headsup(attrs \\ %{}) do
    %Headsup{}
    |> Headsup.changeset(attrs)
    |> Repo.insert()
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
end
