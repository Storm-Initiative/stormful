defmodule Stormful.Planning do
  @moduledoc """
  The Planning context.
  """

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
    todos_query = from t in Todo, order_by: [asc: t.inserted_at]

    Repo.one!(
      from p in Plan,
        where: p.user_id == ^user_id and p.id == ^id,
        preload: [todos: ^todos_query]
    )
  end
end
