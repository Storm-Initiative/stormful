defmodule Stormful.Sensicality.Sensical do
  alias Stormful.FlowingThoughts.Wind
  alias Stormful.Planning.Plan
  alias Stormful.Brainstorming.Thought
  alias Stormful.Accounts.User

  use Ecto.Schema
  import Ecto.Changeset

  schema "sensicals" do
    field :title, :string
    belongs_to :user, User
    has_many :thoughts, Thought
    has_many :winds, Wind
    has_many :plans, Plan

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sensical, attrs) do
    sensical
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title])
  end
end
