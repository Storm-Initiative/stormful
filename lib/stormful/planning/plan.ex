defmodule Stormful.Planning.Plan do
  alias Stormful.TaskManagement.Todo
  alias Stormful.Sensicality.Sensical
  alias Stormful.Accounts.User

  use Ecto.Schema
  import Ecto.Changeset

  schema "plans" do
    field :title, :string
    belongs_to :sensical, Sensical
    belongs_to :user, User
    has_many :todos, Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:title, :sensical_id, :user_id])
    |> validate_required([:title, :sensical_id, :user_id])
  end
end
