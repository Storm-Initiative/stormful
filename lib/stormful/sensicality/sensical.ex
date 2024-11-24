defmodule Stormful.Sensicality.Sensical do
  alias Stormful.Accounts.User

  use Ecto.Schema
  import Ecto.Changeset

  schema "sensicals" do
    field :title, :string
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sensical, attrs) do
    sensical
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title])
  end
end
