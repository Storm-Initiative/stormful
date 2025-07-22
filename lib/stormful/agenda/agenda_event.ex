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
end
