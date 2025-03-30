defmodule Stormful.Starring.StarredSensical do
  @moduledoc false

  alias Stormful.Sensicality.Sensical
  alias Stormful.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "starred_sensicals" do
    belongs_to :user, User
    belongs_to :sensical, Sensical

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(starred_sensical, attrs) do
    starred_sensical
    |> cast(attrs, [:user_id, :sensical_id])
    |> validate_required([:user_id, :sensical_id])
  end
end
