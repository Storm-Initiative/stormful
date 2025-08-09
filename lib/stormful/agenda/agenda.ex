defmodule Stormful.Agenda.Agenda do
  @moduledoc """
  This module defines the Agenda schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Stormful.Accounts.User

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "agendas" do
    field :name, :string
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(agenda, attrs) do
    agenda
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name, name: :agendas_user_id_name_index)
  end

  @doc """
  Converts an agenda struct to a JSON-serializable map.
  """
  def to_json(%__MODULE__{} = agenda) do
    %{
      id: agenda.id,
      name: agenda.name,
      user_id: agenda.user_id,
      inserted_at: agenda.inserted_at,
      updated_at: agenda.updated_at
    }
  end
end
