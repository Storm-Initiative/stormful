defmodule Stormful.Boards.Board do
  use Ecto.Schema
  import Ecto.Changeset

  schema "boards" do
    field :description, :string
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end
end
