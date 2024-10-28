defmodule Stormful.Archives do
  @moduledoc """
  The Archives context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Brainstorming.Thought
  alias Stormful.Repo

  alias Stormful.Archives.Archive

  @doc """
  Returns the list of archives.

  ## Examples

      iex> list_archives()
      [%Archive{}, ...]

  """

  def list_archives do
    []
    # Repo.all(Archive)
  end

  @doc """
  Gets a single archive.

  Raises `Ecto.NoResultsError` if the Archive does not exist.

  ## Examples

      iex> get_archive!(123)
      %Archive{}

      iex> get_archive!(456)
      ** (Ecto.NoResultsError)

  """
  def get_archive!(id, user) do
    thoughts_query = from t in Thought, order_by: t.created_at

    Repo.one!(
      from a in Archive,
        join: t in assoc(a, :thoughts),
        where: a.user_id == ^user.id and a.id == ^id,
        preload: [thoughts: ^thoughts_query]
    )
  end

  @doc """
  Creates a archive.

  ## Examples

      iex> create_archive(%{field: value})
      {:ok, %Archive{}}

      iex> create_archive(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_archive(attrs \\ %{}) do
    %Archive{}
    |> Archive.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a archive.

  ## Examples

      iex> update_archive(archive, %{field: new_value})
      {:ok, %Archive{}}

      iex> update_archive(archive, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_archive(%Archive{} = archive, attrs) do
    archive
    |> Archive.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a archive.

  ## Examples

      iex> delete_archive(archive)
      {:ok, %Archive{}}

      iex> delete_archive(archive)
      {:error, %Ecto.Changeset{}}

  """
  def delete_archive(%Archive{} = archive) do
    Repo.delete(archive)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking archive changes.

  ## Examples

      iex> change_archive(archive)
      %Ecto.Changeset{data: %Archive{}}

  """
  def change_archive(%Archive{} = archive, attrs \\ %{}) do
    Archive.changeset(archive, attrs)
  end
end
