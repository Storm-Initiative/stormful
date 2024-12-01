defmodule Stormful.TaskManagement do
  @moduledoc """
  The TaskManagement context.
  """

  import Ecto.Query, warn: false
  # alias Stormful.Brainstorming
  alias Stormful.Repo

  alias Stormful.TaskManagement.Todo

  @doc """
  Returns the list of todos.

  ## Examples

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos(user) do
    Repo.all(from t in Todo, where: t.user_id == ^user.id)
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Gets a single todo authorized by user_id.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(1, 123)
      %Todo{}

      iex> get_todo!(2, 456)
      ** (Ecto.NoResultsError)

  """
  def get_todo_with_user_id!(user_id, id),
    do: Repo.one!(from t in Todo, where: t.user_id == ^user_id and t.id == ^id)

  @doc """
  Creates a todo.

  ## Examples

      iex> create_todo(%{field: value})
      {:ok, %Todo{}}

      iex> create_todo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{field: new_value})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changeset{data: %Todo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Create a todo from a thought and connect them loosely(no relation-hermit)

  ## Examples 

      iex> create_todo_from_thought(thought_id)
      {:ok, %Todo{}}

      iex> create_todo_from_thought(schizophrenic_thought_id)
      {:error, %Ecto.Changeset{}}

  """
  def create_todo_from_thought(_thought_id) do
    # we do not create todo now
    # thought = Brainstorming.get_thought!(thought_id)

    # create_todo(%{title: thought.words, loose_thought_link: thought.id})
  end

  @doc """
  Marks a todo as complete/uncomplete.

  ## Examples

      iex> complete_todo(todo)
      {:ok, %Todo{}}

      iex> complete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def mark_todo(user_id, todo_id, completed) do
    todo = get_todo_with_user_id!(user_id, todo_id)

    {:ok, date} = DateTime.now("Etc/UTC")

    case completed do
      true ->
        update_todo(todo, %{completed_at: date})

      false ->
        update_todo(todo, %{completed_at: nil})
    end
  end
end
