defmodule StormfulWeb.Sensicality.TheSensicalLive do
  alias Stormful.Starring
  alias StormfulWeb.Sensicality.LiveComponents.Headsups
  alias Stormful.Attention
  alias StormfulWeb.Sensicality.LiveComponents.Todos
  alias Stormful.Planning
  alias Stormful.FlowingThoughts
  alias StormfulWeb.Sensicality.LiveComponents.Thoughts
  alias StormfulWeb.Layouts

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful
  import StormfulWeb.SensicalityComponents.TabComponents

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    sensical = Sensicality.get_sensical!(current_user.id, params["sensical_id"])
    plans = sensical.plans

    starred_sensicality = Starring.get_starred_sensical(current_user.id, sensical.id)

    # We unsub from any
    FlowingThoughts.unsubscribe_from_sensical(sensical)
    Planning.unsubscribe_from_preferred_plan(current_user, sensical)
    Attention.unsubscribe_from_sensical(sensical)

    {:ok,
     socket
     |> assign_controlful()
     |> assign(sensical: sensical)
     |> assign(is_starred: starred_sensicality != nil)
     |> stream(:plans, plans), layout: {Layouts, :sensicality}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, action, _params) do
    representable_action_name = Atom.to_string(action) |> String.replace("_", "-")

    current_tab_title =
      representable_action_name |> String.replace("-", " ") |> String.capitalize()

    little_title_label =
      Enum.random([
        "currently @",
        "@",
        "right @",
        "now you are @",
        "you are viewing the",
        "you seem to be hangin out @",
        "hey, this is",
        "how's the weather at",
        "no way, you are at",
        "you know your stuff if you are @",
        "hi from",
        "this is",
        "hmm, you seem to be @"
      ])

    socket
    |> assign_neededs_for_action(action)
    |> assign(:current_action, action)
    |> assign(:current_tab, representable_action_name)
    |> assign(:current_tab_title, current_tab_title)
    |> assign(:little_title_label, little_title_label)
  end

  defp assign_neededs_for_action(socket, :thoughts) do
    # subscribe to thoughts, this is managed from the center, and not encapsulated for performance
    FlowingThoughts.subscribe_to_sensical(socket.assigns.sensical)

    socket
  end

  defp assign_neededs_for_action(socket, :todos) do
    # subscribe to thoughts, this is managed from the center, and not encapsulated for performance
    current_user = socket.assigns.current_user

    Planning.subscribe_to_preferred_plan(current_user, socket.assigns.sensical)

    socket
  end

  defp assign_neededs_for_action(socket, :heads_ups) do
    # subscribe to thoughts, this is managed from the center, and not encapsulated for performance
    Attention.subscribe_to_sensical(socket.assigns.sensical)

    socket
  end

  defp assign_neededs_for_action(socket, _) do
    socket
  end

  @impl true
  def handle_info({:marked_todo, todo}, socket) do
    # Send the update to the Thoughts component
    send_update(Todos, id: "todos-general", marked_todo: todo)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_todo, todo}, socket) do
    # Send the update to the Todos component
    send_update(Todos, id: "todos-general", todo: todo)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_wind, wind}, socket) do
    # Send the update to the Thoughts component
    send_update(Thoughts, id: "thoughts-general", wind: wind)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_headsup, headsup}, socket) do
    # Send the update to the Headsups component
    send_update(Headsups, id: "headsups-general", headsup: headsup)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    sensical = socket.assigns.sensical

    if tab == "thoughts" do
      {:noreply, socket |> push_patch(to: ~p"/sensicality/#{sensical.id}")}
    else
      {:noreply, socket |> push_patch(to: "/sensicality/#{sensical.id}/#{tab}")}
    end
  end

  @impl true
  def handle_event("star_the_sensical", _, socket) do
    current_user = socket.assigns.current_user
    sensical = socket.assigns.sensical

    {:ok, _} = Starring.star_the_sensical(current_user.id, sensical.id)

    {:noreply,
     socket |> assign(is_starred: true) |> put_flash(:info, "Sensical starred successfully!")}
  end

  @impl true
  def handle_event("unstar_the_sensical", _, socket) do
    current_user = socket.assigns.current_user
    sensical = socket.assigns.sensical

    {:ok, _} = Starring.unstar_the_sensical(current_user.id, sensical.id)

    {:noreply,
     socket |> assign(is_starred: false) |> put_flash(:info, "Sensical unstarred successfully!")}
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
