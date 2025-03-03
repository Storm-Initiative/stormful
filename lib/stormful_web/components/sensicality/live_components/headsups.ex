defmodule StormfulWeb.Sensicality.LiveComponents.Headsups do
  @moduledoc false
  alias Stormful.Attention
  alias Stormful.Attention.Headsup
  import StormfulWeb.CoreComponents

  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{headsup: headsup}, socket) do
    {:ok,
     stream_insert(socket, :headsups, headsup)
     |> push_event("scroll-to-latest-wind", %{})}
  end

  @impl true
  def update(assigns, socket) do
    sensical = assigns.sensical
    current_user = assigns.current_user
    headsups = Attention.list_headsups_for_sensical(current_user.id, sensical.id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> stream(:headsups, headsups)}
  end

  attr :headsup, Headsup
  attr :target, :any

  def headsup(assigns) do
    ~H"""
    <div class="group">
      <div class="flex items-center gap-3 px-6 py-6 bg-black/70 rounded-lg hover:bg-black/50 transition-all duration-300 overflow-x-auto">
        <div class="flex-shrink-0">
          <div class="w-10 h-10 rounded-full bg-blue-500/70 group-hover:bg-blue-400/80 flex items-center justify-center transition-colors">
            <.icon name="hero-exclamation-circle" class="w-6 h-6 text-white" />
          </div>
        </div>
        <div class="flex flex-col">
          <p class="text-2xl text-white/90 font-bold leading-relaxed break-normal">
            {@headsup.title}
          </p>
          <div class="flex items-center">
            <%= if @headsup.inserted_at do %>
              <span class="text-sm text-white/60">
                {Calendar.strftime(@headsup.inserted_at, "added %B %d, %Y @ %I:%M %p UTC+0")}
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="p-8 pt-0 flex flex-col gap-4"
      id="headsups"
      phx-hook="WindScroller"
      phx-update="stream"
    >
      <div :for={{dom_id, headsup} <- @streams.headsups} dom_id={dom_id} id={dom_id}>
        <!-- todo => make in this wind context -->
        <.headsup headsup={headsup} target={@myself} />
      </div>
    </div>
    """
  end
end
