defmodule StormfulWeb.AgendaLive.Index do
  alias Stormful.Utils.TimeRelated
  alias Stormful.ProfileManagement
  use StormfulWeb, :live_view

  alias Stormful.AgendaRelated
  alias Stormful.Agenda.AgendaEvent

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    current_user_id = current_user.id
    user_timezone = ProfileManagement.get_user_timezone(current_user)

    agenda = AgendaRelated.get_users_agenda(current_user_id)
    events = AgendaRelated.list_agenda_events(current_user_id, agenda.id)

    {:ok,
     socket
     |> assign(user_timezone: user_timezone)
     |> assign(:agenda, agenda)
     |> stream(:events, events)
     |> assign(:show_create_modal, false)
     |> assign_empty_new_agenda_event_form_to_socket}
  end

  @impl true
  def handle_params(_, _, socket) do
    is_new_event_mode = socket.assigns.live_action == :new_event

    {:noreply, socket |> assign(:show_create_modal, is_new_event_mode)}
  end

  @impl true
  def handle_event("show-create-modal", _, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/agenda/events/new")}
  end

  @impl true
  def handle_event("save_event", %{"agenda_event" => agenda_event_params}, socket) do
    current_user = socket.assigns.current_user
    current_user_id = current_user.id

    current_agenda = socket.assigns.agenda
    current_agenda_id = current_agenda.id
    # we need to plant 2 more to this tho, user_id and agenda_id
    {res, changeset} =
      AgendaRelated.create_agenda_event(
        current_user_id,
        agenda_event_params
        |> Map.put("agenda_id", current_agenda_id)
      )

    if res == :error do
      {:noreply, socket |> assign_new_agenda_event_form_to_socket(changeset)}
    else
      {:noreply,
       socket
       |> assign_empty_new_agenda_event_form_to_socket()
       |> push_patch(to: ~p"/agenda")
       |> stream_insert(:events, changeset, at: 0)}
    end
  end

  def assign_empty_new_agenda_event_form_to_socket(socket) do
    socket
    |> assign_new_agenda_event_form_to_socket(AgendaRelated.change_agenda_event(%AgendaEvent{}))
  end

  def assign_new_agenda_event_form_to_socket(socket, changeset) do
    socket
    |> assign(new_agenda_event_form: to_form(changeset))
  end
end
