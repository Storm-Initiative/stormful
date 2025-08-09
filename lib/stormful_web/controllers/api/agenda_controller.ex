defmodule StormfulWeb.Api.AgendaController do
  use StormfulWeb, :controller

  alias Stormful.AgendaRelated
  alias Stormful.Agenda.{Agenda, AgendaEvent}

  action_fallback StormfulWeb.Api.FallbackController

  def index(conn, _params) do
    user = conn.assigns.current_user
    agendas = AgendaRelated.list_agendas(user.id)

    case agendas do
      [] ->
        # User has no agenda - return empty response with 200
        conn
        |> put_status(:ok)
        |> json(%{})

      [agenda | _] ->
        # User has agenda - return agenda data as JSON
        conn
        |> put_status(:ok)
        |> json(Agenda.to_json(agenda))
    end
  end

  def events(conn, _params) do
    user = conn.assigns.current_user
    agendas = AgendaRelated.list_agendas(user.id)

    case agendas do
      [] ->
        # User has no agenda - return empty array with 200
        conn
        |> put_status(:ok)
        |> json([])

      [agenda | _] ->
        # User has agenda - fetch events (already ordered by event_date at DB level)
        events = AgendaRelated.list_agenda_events(agenda.id)

        events_data = Enum.map(events, &AgendaEvent.to_json/1)

        conn
        |> put_status(:ok)
        |> json(events_data)
    end
  end
end
