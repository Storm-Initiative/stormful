defmodule Stormful.Attention.Headsup do
  @moduledoc false

  alias Stormful.Accounts.User
  alias Stormful.Sensicality.Sensical
  use Ecto.Schema
  import Ecto.Changeset

  schema "headsups" do
    field :description, :string
    field :title, :string

    belongs_to :user, User
    belongs_to :sensical, Sensical

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(headsup, attrs) do
    headsup
    |> cast(attrs, [:title, :description, :user_id, :sensical_id])
    |> validate_required([:title, :user_id])
    |> validate_length(:title, min: 1, max: 255)
  end
end
