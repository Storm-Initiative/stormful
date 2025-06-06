defmodule StormfulWeb.Sensicality.ThoughtsLive do
  alias Stormful.Starring
  alias Stormful.Attention
  alias Stormful.Planning
  alias Stormful.FlowingThoughts
  alias StormfulWeb.Layouts

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    sensical = Sensicality.get_sensical!(current_user.id, params["sensical_id"])
    winds = FlowingThoughts.list_winds_by_sensical(sensical.id, current_user.id, :desc)
    plans = sensical.plans

    starred_sensicality = Starring.get_starred_sensical(current_user.id, sensical.id)

    FlowingThoughts.subscribe_to_sensical(sensical)

    {:ok,
     socket
     |> assign(sensical: sensical)
     |> assign(is_starred: starred_sensicality != nil)
     |> stream(:plans, plans)
     |> stream(:winds, winds), layout: {Layouts, :sensicality}}
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

  defp assign_neededs_for_action(socket, _) do
    socket
  end

  @impl true
  def handle_info({:new_wind, wind}, socket) do
    {:noreply,
     socket
     |> stream_insert(:winds, wind, at: 0)}
    #  |> push_event("scroll-to-latest-wind", %{})}
  end

  @impl true
  def handle_event("star_the_sensical", _, socket) do
    current_user = socket.assigns.current_user
    sensical = socket.assigns.sensical

    {:ok, _} = Starring.star_the_sensical(current_user.id, sensical.id)

    # now, refetch the sensical
    sensical = Sensicality.get_sensical!(current_user.id, sensical.id)

    {:noreply,
     socket |> assign(sensical: sensical) |> put_flash(:info, "Sensical starred successfully!")}
  end

  @impl true
  def handle_event("unstar_the_sensical", _, socket) do
    current_user = socket.assigns.current_user
    sensical = socket.assigns.sensical

    {:ok, _} = Starring.unstar_the_sensical(current_user.id, sensical.id)

    # now, refetch the sensical
    sensical = Sensicality.get_sensical!(current_user.id, sensical.id)

    {:noreply,
     socket |> assign(sensical: sensical) |> put_flash(:info, "Sensical unstarred successfully!")}
  end
end
