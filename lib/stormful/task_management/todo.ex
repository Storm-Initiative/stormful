defmodule Stormful.TaskManagement.Todo do
  alias Stormful.Accounts.User

  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :description, :string
    field :title, :string
    field :completed_at, :naive_datetime
    field :loose_thought_link, :integer
    field :plan_id, :integer
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :completed_at, :loose_thought_link, :plan_id])
    |> validate_required([:title, :loose_thought_link])
  end
end
