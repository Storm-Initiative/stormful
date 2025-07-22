defmodule StormfulWeb.AgendaLive.Index do
  use StormfulWeb, :live_view

  alias Stormful.AgendaRelated

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    agendas = AgendaRelated.list_agendas(current_user.id)

    # Fetch events for each agenda
    agendas_with_events = Enum.map(agendas, fn agenda ->
      events = AgendaRelated.list_agenda_events(agenda.id)
      Map.put(agenda, :events, events)
    end)

    {:ok,
     socket
     |> assign(:agendas, agendas_with_events)
     |> assign(:agenda_form, to_form(AgendaRelated.change_agenda(%Stormful.Agenda.Agenda{})))
     |> assign(:show_create_modal, false)
     |> assign(:has_agenda, length(agendas) > 0), layout: {StormfulWeb.Layouts, :agenda_center}}
  end

  @impl true
  def handle_event("show-create-modal", _, socket) do
    {:noreply, socket |> assign(:show_create_modal, true)}
  end

  @impl true
  def handle_event("hide-create-modal", _, socket) do
    {:noreply, socket |> assign(:show_create_modal, false)}
  end

  @impl true
  def handle_event("create-agenda", %{"agenda" => agenda_params}, socket) do
    current_user = socket.assigns.current_user

    if socket.assigns.has_agenda do
      {:noreply, socket |> put_flash(:error, "You can only have one agenda")}
    else
      case AgendaRelated.create_agenda(Map.put(agenda_params, "user_id", current_user.id)) do
        {:ok, agenda} ->
          agenda_with_events = Map.put(agenda, :events, [])
          {:noreply,
           socket
           |> assign(:agendas, [agenda_with_events])
           |> assign(:has_agenda, true)
           |> assign(:show_create_modal, false)
           |> assign(:agenda_form, to_form(AgendaRelated.change_agenda(%Stormful.Agenda.Agenda{})))
           |> put_flash(:info, "Agenda created successfully!")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, socket |> assign(:agenda_form, to_form(changeset))}
      end
    end
  end

  @impl true
  def handle_event("delete-agenda", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user

    case AgendaRelated.get_agenda!(current_user.id, id) do
      agenda ->
        case AgendaRelated.delete_agenda(agenda) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(:agendas, [])
             |> assign(:has_agenda, false)
             |> put_flash(:info, "Agenda deleted successfully!")}

          {:error, _} ->
            {:noreply, socket |> put_flash(:error, "Failed to delete agenda")}
        end

      _ ->
        {:noreply, socket |> put_flash(:error, "Agenda not found")}
    end
  end
end
