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
    winds = get_sensical_winds_paginated(sensical.id, current_user.id, 0)
    plans = sensical.plans

    starred_sensicality = Starring.get_starred_sensical(current_user.id, sensical.id)

    FlowingThoughts.subscribe_to_sensical(sensical)

    {:ok,
     socket
     |> assign(sensical: sensical)
     |> assign(is_starred: starred_sensicality != nil)
     |> assign_pagination_state()
     |> assign(winds_loaded: length(winds))
     |> assign(has_more: length(winds) >= 20)
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

  @impl true
  def handle_event("load-more", _, socket) do
    if socket.assigns.sensical && !socket.assigns.loading && socket.assigns.has_more do
      # Set loading state first
      socket = assign(socket, :loading, true)
      
      current_offset = socket.assigns.winds_loaded
      sensical_id = socket.assigns.sensical.id
      user_id = socket.assigns.current_user.id

      new_winds = get_sensical_winds_paginated(sensical_id, user_id, current_offset)

      socket =
        socket
        |> assign(loading: false)
        |> assign(winds_loaded: current_offset + length(new_winds))
        |> assign(has_more: length(new_winds) >= 20)

      # Add new winds to the stream
      socket =
        Enum.reduce(new_winds, socket, fn wind, acc ->
          stream_insert(acc, :winds, wind)
        end)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp assign_pagination_state(socket) do
    socket
    |> assign(:loading, false)
    |> assign(:has_more, true)
    |> assign(:winds_loaded, 0)
  end

  defp get_sensical_winds_paginated(sensical_id, user_id, offset) do
    FlowingThoughts.list_winds_by_sensical_paginated(sensical_id, user_id, 
      sort_order: :desc, 
      limit: 20, 
      offset: offset
    )
  end
end
