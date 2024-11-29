defmodule Stormful.Planning.Plan do
  alias Stormful.TaskManagement.Todo
  alias Stormful.Sensicality.Sensical

  use Ecto.Schema
  import Ecto.Changeset

  schema "plans" do
    field :title, :string
    belongs_to :sensical, Sensical
    has_many :todos, Todo

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:title, :sensical_id])
    |> validate_required([:title, :sensical_id])
  end
end
