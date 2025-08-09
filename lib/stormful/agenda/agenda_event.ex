defmodule Stormful.Agenda.AgendaEvent do
  @moduledoc """
  This module defines the AgendaEvent schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Stormful.Agenda.Agenda
  alias Stormful.Accounts.User

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "agenda_events" do
    field :the_event, :string
    field :event_date, :utc_datetime
    belongs_to :agenda, Agenda, type: Ecto.ULID
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(agenda_event, attrs) do
    agenda_event
    |> cast(attrs, [:the_event, :event_date, :agenda_id, :user_id])
    |> validate_required([:the_event, :event_date, :agenda_id, :user_id])
    |> unique_constraint([:agenda_id, :the_event, :event_date],
      name: :agenda_events_agenda_id_the_event_event_date_index
    )
  end

  @doc """
  Converts an agenda event struct to a JSON-serializable map.
  """
  def to_json(%__MODULE__{} = agenda_event) do
    %{
      id: agenda_event.id,
      the_event: agenda_event.the_event,
      event_date: agenda_event.event_date,
      agenda_id: agenda_event.agenda_id,
      user_id: agenda_event.user_id,
      inserted_at: agenda_event.inserted_at,
      updated_at: agenda_event.updated_at
    }
  end
end
