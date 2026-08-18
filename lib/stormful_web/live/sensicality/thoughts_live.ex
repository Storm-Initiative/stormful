defmodule StormfulWeb.Sensicality.ThoughtsLive do
  alias Stormful.ProfileManagement
  alias Stormful.Starring
  alias Stormful.FlowingThoughts

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view

  @winds_per_scroll 20

  def get_tempest_source_link(tempest_starter_wind) do
    if is_nil(tempest_starter_wind) do
      nil
    else
      sensical_id = tempest_starter_wind.sensical_id

      if sensical_id do
        ~p"/sensicality/#{sensical_id}"
      else
        ~p"/journal"
      end
    end
  end

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user
    user_timezone = ProfileManagement.get_user_timezone(current_user)

    sensical = Sensicality.get_sensical!(current_user.id, params["sensical_id"])
    is_tempest = not is_nil(sensical.is_tempest_of)
    tempest_source_link = get_tempest_source_link(sensical.is_tempest_of)

    winds = get_sensical_winds_paginated(sensical.id, current_user.id, 0)

    plans = sensical.plans

    ProfileManagement.update_the_latest_visited_sensical_id_of_the_user(current_user, sensical.id)

    starred_sensicality = Starring.get_starred_sensical(current_user.id, sensical.id)

    FlowingThoughts.subscribe_to_sensical(sensical)

    {:ok,
     socket
     |> assign(user_timezone: user_timezone)
     |> assign(sensical: sensical)
     |> assign(is_starred: starred_sensicality != nil)
     |> assign(is_tempest: is_tempest)
     |> assign(tempest_source_link: tempest_source_link)
     |> assign_pagination_state()
     |> assign(winds_loaded: length(winds))
     |> assign(has_more: length(winds) >= @winds_per_scroll)
     |> stream(:plans, plans)
     |> stream(:winds, winds)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, action, _params) do
    is_read_mode = action == :read_mode

    user_id = socket.assigns.current_user.id
    sensical_id = socket.assigns.sensical.id

    if is_read_mode do
      winds = FlowingThoughts.list_winds_by_sensical(sensical_id, user_id)

      socket |> assign(read_mode_on: true) |> assign(winds: winds)
    else
      socket |> assign(read_mode_on: false)
    end
  end

  @impl true
  def handle_info({:new_wind, wind}, socket) do
    {:noreply,
     socket
     |> stream_insert(:winds, wind, at: 0)}

    #  |> push_event("scroll-to-latest-wind", %{})}
  end

  @impl true
  def handle_event("create-tempest-from-wind", %{"wind-id" => wind_id}, socket) do
    current_user = socket.assigns.current_user

    {:ok, tempest} = FlowingThoughts.make_wind_into_tempest(current_user.id, wind_id)

    {:noreply,
     socket
     |> put_flash(:info, "Tempest initialized ⚡")
     |> push_navigate(to: ~p"/sensicality/#{tempest.id}")}
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
        |> assign(has_more: length(new_winds) >= @winds_per_scroll)

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
      limit: @winds_per_scroll,
      offset: offset
    )
  end
end
