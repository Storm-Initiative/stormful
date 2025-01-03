defmodule Stormful.FlowingThoughts.Wind do
  alias Stormful.Sensicality.Sensical
  alias Stormful.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "winds" do
    field :words, :string
    field :long_words, :string
    belongs_to :user, User
    belongs_to :sensical, Sensical

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(wind, attrs) do
    wind
    |> cast(attrs, [:words, :long_words, :user_id, :sensical_id])
    |> validate_required([:words, :user_id])
  end
end
