defmodule Stormful.TaskManagement do
  @moduledoc """
  The TaskManagement context.
  """

  import Ecto.Query, warn: false
  # alias Stormful.Brainstorming
  alias Stormful.Planning
  alias Stormful.AiRelated.AnthropicClient
  alias Stormful.Sensicality
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
  Creates a todo for a sensical's preferred plan, authenticates by user_id.

  ## Examples

      iex> create_todo_for_sensicals_preferred_plan(1, 2, "buy some bread")
      {:ok, %Todo{}}

      iex> create_todo_for_sensicals_preferred_plan(5, 2, "dont buy some bread")
      {:error, %Ecto.Changeset{}}

  """
  def create_todo_for_sensicals_preferred_plan(user_id, sensical_id, title) do
    plan = Planning.get_preferred_plan_of_sensical!(user_id, sensical_id)

    %Todo{}
    |> Todo.changeset(%{
      title: title,
      user_id: user_id,
      plan_id: plan.id
    })
    |> Repo.insert()
  end

  @doc """
  Creates many todos, at once, for a user/plan

  ## Examples

      iex> create_todos_for_plan(user_id, plan_id, [%{title: "heyy"}])
      {:ok}

      iex> create_todos_for_plan(user_id, plan_id, [%{}])
      {:error}

  """
  def create_todos_for_plan(user_id, plan_id, todos) do
    # every todo will have %{title: str} in it, we gotta add user_id and plan_id
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    enhanced_todos =
      todos
      |> Enum.map(fn todo ->
        %{
          title: todo["title"],
          user_id: user_id,
          plan_id: plan_id,
          inserted_at: now,
          updated_at: now
        }
      end)

    Todo
    |> Repo.insert_all(enhanced_todos)
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

  def create_plan_from_thoughts_in_a_sensical(user_id, sensical_id) do
    sensical = Sensicality.get_sensical!(user_id, sensical_id)

    # now, we got the sensical with thoughts preloaded
    # we just gotta make the list for it w every thought
    # with all those thoughts, we'll go ahead and make a request to our AI provider

    # so, let's begin
    # we gonna map it to make it look like this => [%{"role" => "user", "content" => "Ah! ca ira"}], # ca, cuz English standards whatever
    cumulative_thoughts =
      sensical.winds
      |> Enum.map(fn wind -> %{"role" => "user", "content" => wind.words} end)

    response_from_ai =
      AnthropicClient.use_messages(
        "claude-3-5-haiku-20241022",
        cumulative_thoughts,
        """
        You are a JSON todo generator that creates only titles. Rules:

        ALWAYS output [{"title": "string"}] format only
        Titles under 255 chars
        Fun and energetic tone matching user input
        Use arrows/symbols(=>, ->, --, +, &, @)  between contexts, and stuff alike to make titles shine
        Consider user's workflow and thought connections
        Add occasional funny todos for encouragement, they can be jokes, some inspirations, or something like that. Do add them in between tasks. Do not indicate that they are jokes, make them seem authentic
        Include a good amount of data inside them. Do not overexplain, but no need to be short too
        You may use user's preferred language if it hasn't been stated in their thoughts otherwise. If user uses that lang %80 of the time, they prefer it, if not stated otherwise.

        Example:
        [{"title":"Build schema -> title:str + count:int 🚀"},{"title":"Grab those perfect bananas => not huge/tiny 🍌",{"title":"Remember to take a breath"}}]
        """,
        4096
      )

    content = response_from_ai.body["content"]
    [meaty_part] = content
    text_part = meaty_part["text"]

    {:ok, todos_to_be_created} = Jason.decode(text_part)

    {:ok, new_plan} =
      Planning.create_plan(%{
        user_id: user_id,
        title: "AI generated plan",
        sensical_id: sensical.id
      })

    create_todos_for_plan(user_id, new_plan.id, todos_to_be_created)

    {:ok, new_plan}
  end
end
