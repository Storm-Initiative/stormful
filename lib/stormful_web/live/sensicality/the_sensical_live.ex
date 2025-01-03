defmodule StormfulWeb.Sensicality.TheSensicalLive do
  alias Stormful.FlowingThoughts
  alias Stormful.TaskManagement
  alias Stormful.Planning
  alias Stormful.Brainstorming.Thought
  alias StormfulWeb.Sensicality.Plans.PlanContainerLive
  alias Stormful.Brainstorming

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

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
     |> stream(:plans, plans)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new_plan, _params) do
    socket
  end

  defp apply_action(socket, :with_plan, params) do
    current_user = socket.assigns.current_user

    plan = Planning.get_plan_from_sensical!(current_user.id, params["plan_id"])

    socket |> assign(selected_plan: plan)
  end

  defp apply_action(socket, _, _params) do
    socket
  end

  @impl true
  def handle_info({:new_wind, wind}, socket) do
    {:noreply, stream_insert(socket, :winds, wind) |> push_event("scroll-to-latest-wind", %{})}
  end

  @impl true
  def handle_info({StormfulWeb.Sensicality.Plans.FormComponent, {:plan_created, plan}}, socket) do
    {:noreply, socket |> stream_insert(:plans, plan)}
  end

  @impl true
  def handle_event("do-ai-stuff", _, socket) do
    current_user = socket.assigns.current_user

    {:ok, the_glorious_plan} =
      TaskManagement.create_plan_from_thoughts_in_a_sensical(
        current_user.id,
        socket.assigns.sensical.id
      )

    {:noreply, socket |> stream_insert(:plans, the_glorious_plan)}
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
