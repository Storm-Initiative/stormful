defmodule Stormful.Archives.Archive do
  alias Stormful.Accounts.User

  use Ecto.Schema
  import Ecto.Changeset

  schema "archives" do
    field :context, :string
    field :color_code, :string
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(archive, attrs) do
    archive
    |> cast(attrs, [:context, :color_code, :user_id])
    |> validate_required([:context, :color_code])
    |> unique_constraint([:context, :user_id])
  end
end
