defmodule Stormful.Brainstorming do
  @moduledoc """
  The Brainstorming context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo

  alias Stormful.Brainstorming.Thought

  @doc """
  Returns the list of thoughts. Not archived

  ## Examples

      iex> list_thoughts()
      [%Thought{}, ...]

  """
  def list_thoughts(user) do
    Repo.all(
      from t in Thought,
        where: t.archived == false and t.user_id == ^user.id,
        order_by: [desc: t.inserted_at]
    )
  end

  # TODO: we can implement "load on scroll here, you know to not ddos ourselves or something"
  @doc """
  Returns the list of thoughts. Archived and not archived

  ## Examples

      iex> list_archived_thoughts()
      [%Thought{}, ...]

  """
  def list_archived_included_thoughts(user) do
    Repo.all(from t in Thought, where: t.user_id == ^user.id, order_by: [desc: t.inserted_at])
  end

  @doc """
  Gets a single thought.

  Raises `Ecto.NoResultsError` if the Thought does not exist.

  ## Examples

      iex> get_thought!(123)
      %Thought{}

      iex> get_thought!(456)
      ** (Ecto.NoResultsError)

  """
  def get_thought!(id, user),
    do: Repo.one!(from t in Thought, where: t.user_ud == ^user.id and t.id == ^id)

  @doc """
  Creates a thought.

  ## Examples

      iex> create_thought(%{field: value})
      {:ok, %Thought{}}

      iex> create_thought(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_thought(attrs \\ %{}) do
    %Thought{}
    |> Thought.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a thought.

  ## Examples

      iex> update_thought(thought, %{field: new_value})
      {:ok, %Thought{}}

      iex> update_thought(thought, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_thought(%Thought{} = thought, attrs) do
    thought
    |> Thought.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a thought.

  ## Examples

      iex> delete_thought(thought)
      {:ok, %Thought{}}

      iex> delete_thought(thought)
      {:error, %Ecto.Changeset{}}

  """
  def delete_thought(%Thought{} = thought) do
    Repo.delete(thought)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking thought changes.

  ## Examples

      iex> change_thought(thought)
      %Ecto.Changeset{data: %Thought{}}

  """
  def change_thought(%Thought{} = thought, attrs \\ %{}) do
    Thought.changeset(thought, attrs)
  end

  @doc """
  Archives all the thoughts, beautiful for clearing the screen

  ## Example
      iex> archive_all()
      {no_of_changed, nil}
  """
  def archive_all(user) do
    Repo.update_all(
      from(t in Thought,
        where: t.archived != ^true and t.user_id == ^user.id,
        update: [set: [archived: true]]
      ),
      []
    )
  end
end
