defmodule Stormful.Journaling.Journal do
  @moduledoc false

  alias Stormful.Accounts.User
  alias Stormful.FlowingThoughts.Wind

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "journals" do
    field :title, :string
    field :description, :string
    field :default, :boolean, default: false

    belongs_to :user, User
    has_many :winds, Wind

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(journal, attrs) do
    journal
    |> cast(attrs, [:title, :description, :user_id, :default])
    |> validate_required([:title, :user_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
  end
end
