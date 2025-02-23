defmodule Stormful.Planning do
  @moduledoc """
  The Planning context.
  """

  @pubsub Stormful.PubSub

  import Ecto.Query, warn: false
  alias Stormful.TaskManagement.Todo
  alias Stormful.Repo

  alias Stormful.Planning.Plan

  @doc """
  Returns the list of plans.

  ## Examples

      iex> list_plans()
      [%Plan{}, ...]

  """
  def list_plans do
    Repo.all(Plan)
  end

  @doc """
  Gets a single plan.

  Raises `Ecto.NoResultsError` if the Plan does not exist.

  ## Examples

      iex> get_plan!(123)
      %Plan{}

      iex> get_plan!(456)
      ** (Ecto.NoResultsError)

  """
  def get_plan!(id), do: Repo.get!(Plan, id)

  @doc """
  Creates a plan.

  ## Examples

      iex> create_plan(%{field: value})
      {:ok, %Plan{}}

      iex> create_plan(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a plan for a Sencsical, authenticated by user_id.

  ## Examples

      iex> create_plan_for_a_sensical(1, 2, false)
      {:ok, %Plan{}}

      iex> create_plan_for_a_sensical(4, 5, true)
      {:error, %Ecto.Changeset{}}

  """
  def create_plan_for_a_sensical(user_id, sensical_id, preferred \\ false) do
    create_plan(%{
      user_id: user_id,
      sensical_id: sensical_id,
      preferred: preferred,
      title: "The plan"
    })
  end

  @doc """
  Updates a plan.

  ## Examples

      iex> update_plan(plan, %{field: new_value})
      {:ok, %Plan{}}

      iex> update_plan(plan, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a plan.

  ## Examples

      iex> delete_plan(plan)
      {:ok, %Plan{}}

      iex> delete_plan(plan)
      {:error, %Ecto.Changeset{}}

  """
  def delete_plan(%Plan{} = plan) do
    Repo.delete(plan)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plan changes.

  ## Examples

      iex> change_plan(plan)
      %Ecto.Changeset{data: %Plan{}}

  """
  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    Plan.changeset(plan, attrs)
  end

  @doc """
  Gets a single plan, authorized by the user_id

  Raises `Ecto.NoResultsError` if the Plan does not exist.

  ## Examples

      iex> get_plan_from_sensical!(1, 123)
      %Plan{}

      iex> get_plan_from_sensical!(2, 456)
      ** (Ecto.NoResultsError)

  """
  def get_plan_from_sensical!(user_id, id) do
    todos_query = from(t in Todo, order_by: [asc: t.inserted_at])

    Repo.one!(
      from(p in Plan,
        where: p.user_id == ^user_id and p.id == ^id,
        preload: [todos: ^todos_query]
      )
    )
  end

  @doc """
  Gets the preferred plan, determined by sensical_id & authorized by the user_id.

  Raises `Ecto.NoResultsError` if the Plan does not exist.

  ## Examples

      iex> get_preferred_plan_of_sensical!(1, 123)
      %Plan{}

      iex> get_preferred_plan_of_sensical!(2, 456)
      ** (Ecto.NoResultsError)

  """
  def get_preferred_plan_of_sensical!(user_id, sensical_id) do
    todos_query = from(t in Todo, order_by: [asc: t.inserted_at])

    case Repo.one(
           from(p in Plan,
             where:
               p.user_id == ^user_id and p.sensical_id == ^sensical_id and p.preferred == true,
             preload: [todos: ^todos_query]
           )
         ) do
      nil ->
        {:ok, _plan} = create_plan_for_a_sensical(user_id, sensical_id, true)

        Repo.one(
          from(p in Plan,
            where:
              p.user_id == ^user_id and p.sensical_id == ^sensical_id and p.preferred == true,
            preload: [todos: ^todos_query]
          )
        )

      plan ->
        plan
    end
  end

  def subscribe_to_preferred_plan(current_user, sensical) do
    Phoenix.PubSub.subscribe(@pubsub, topic(current_user.id, sensical.id))
  end

  def unsubscribe_from_preferred_plan(current_user, sensical) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(current_user.id, sensical.id))
  end

  defp topic(current_user_id, sensical_id) do
    plan_id = get_preferred_plan_of_sensical!(current_user_id, sensical_id).id
    "plan_room:#{plan_id}"
  end
end
