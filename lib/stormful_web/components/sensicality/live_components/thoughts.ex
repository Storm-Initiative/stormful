defmodule StormfulWeb.Sensicality.LiveComponents.Thoughts do
  alias Stormful.FlowingThoughts
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{wind: wind}, socket) do
    {:ok,
     stream_insert(socket, :winds, wind)
     |> push_event("scroll-to-latest-wind", %{})}
  end

  @impl true
  def update(assigns, socket) do
    sensical = assigns.sensical
    current_user = assigns.current_user

    winds = FlowingThoughts.list_winds_by_sensical(sensical.id, current_user.id)

    {:ok, socket |> stream(:winds, winds)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8 pt-0 flex flex-col gap-4" id="winds" phx-hook="WindScroller" phx-update="stream">
      <div :for={{dom_id, wind} <- @streams.winds} dom_id={dom_id} id={dom_id}>
        <!-- todo => make in this wind context -->
        <StormfulWeb.Thoughts.ThoughtLive.wind wind={wind} />
      </div>
    </div>
    """
  end
end
