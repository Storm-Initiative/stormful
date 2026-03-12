defmodule Stormful.Sensicality.Sensical do
  @moduledoc false

  alias Stormful.FlowingThoughts.Wind
  alias Stormful.Planning.Plan
  alias Stormful.Accounts.User
  alias Stormful.Starring.StarredSensical

  use Ecto.Schema
  import Ecto.Changeset

  schema "sensicals" do
    field :title, :string
    field :summary, :string, default: ""

    belongs_to :user, User
    belongs_to :is_tempest_of, Wind, type: Ecto.ULID

    has_many :winds, Wind
    has_many :plans, Plan
    has_one :starred_sensical, StarredSensical

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sensical, attrs) do
    sensical
    |> cast(attrs, [:title, :user_id, :summary, :is_tempest_of_id])
    |> validate_required([:title])
  end
end
