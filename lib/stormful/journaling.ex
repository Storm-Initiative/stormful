defmodule Stormful.Journaling do
  @moduledoc """
  The Journaling context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo
  alias Stormful.Journaling.Journal
  alias Stormful.FlowingThoughts.Wind

  @max_journals_per_user 3

  @doc """
  Returns the list of journals for a user.

  ## Examples

      iex> list_journals(user_id)
      [%Journal{}, ...]

  """
  def list_journals(user_id) do
    Repo.all(
      from j in Journal,
        where: j.user_id == ^user_id,
        order_by: [asc: j.inserted_at]
    )
  end

  @doc """
  Gets a single journal.

  Raises `Ecto.NoResultsError` if the Journal does not exist.

  ## Examples

      iex> get_journal!(user_id, id)
      %Journal{}

      iex> get_journal!(user_id, invalid_id)
      ** (Ecto.NoResultsError)

  """
  def get_journal!(user_id, id) do
    Repo.one!(
      from j in Journal,
        where: j.user_id == ^user_id and j.id == ^id,
        preload: [winds: ^from(w in Wind, order_by: [desc: w.inserted_at])]
    )
  end

  @doc """
  Creates a journal.

  ## Examples

      iex> create_journal(%{field: value})
      {:ok, %Journal{}}

      iex> create_journal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_journal(attrs \\ %{}) do
    user_id = attrs[:user_id] || attrs["user_id"]

    # Check if user already has max journals
    if user_id && count_user_journals(user_id) >= @max_journals_per_user do
      {:error, :max_journals_reached}
    else
      %Journal{}
      |> Journal.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Updates a journal.

  ## Examples

      iex> update_journal(journal, %{field: new_value})
      {:ok, %Journal{}}

      iex> update_journal(journal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_journal(%Journal{} = journal, attrs) do
    journal
    |> Journal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a journal.

  ## Examples

      iex> delete_journal(journal)
      {:ok, %Journal{}}

      iex> delete_journal(journal)
      {:error, %Ecto.Changeset{}}

  """
  def delete_journal(%Journal{} = journal) do
    Repo.delete(journal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking journal changes.

  ## Examples

      iex> change_journal(journal)
      %Ecto.Changeset{data: %Journal{}}

  """
  def change_journal(%Journal{} = journal, attrs \\ %{}) do
    Journal.changeset(journal, attrs)
  end

  @doc """
  Counts the number of journals for a user.

  ## Examples

      iex> count_user_journals(user_id)
      2

  """
  def count_user_journals(user_id) do
    Repo.aggregate(
      from(j in Journal, where: j.user_id == ^user_id),
      :count
    )
  end
end
