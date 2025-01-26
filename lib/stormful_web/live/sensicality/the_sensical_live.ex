defmodule StormfulWeb.Sensicality.TheSensicalLive do
  alias StormfulWeb.Layouts
  alias Stormful.FlowingThoughts
  alias Stormful.Planning

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful
  import StormfulWeb.SensicalityComponents.TabComponents

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    sensical = Sensicality.get_sensical!(current_user.id, params["sensical_id"])
    winds = sensical.winds
    plans = sensical.plans

    FlowingThoughts.subscribe_to_sensical(sensical)

    {:ok,
     socket
     |> assign_controlful()
     |> assign(sensical: sensical)
     |> stream(:winds, winds)
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

    socket
    |> assign(:current_tab, representable_action_name)
    |> assign(:current_tab_title, current_tab_title)
  end

  @impl true
  def handle_info({:new_wind, wind}, socket) do
    {:noreply, stream_insert(socket, :winds, wind) |> push_event("scroll-to-latest-wind", %{})}
  end

  @impl true
  def handle_info({StormfulWeb.Sensicality.Plans.FormComponent, {:plan_created, plan}}, socket) do
    {:noreply, socket |> stream_insert(:plans, plan)}
  end

  def handle_event("select_tab", %{"tab" => tab}, socket) do
    sensical = socket.assigns.sensical

    if tab == "thoughts" do
      {:noreply, socket |> push_patch(to: ~p"/sensicality/#{sensical.id}")}
    else
      {:noreply, socket |> push_patch(to: "/sensicality/#{sensical.id}/#{tab}")}
    end
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
