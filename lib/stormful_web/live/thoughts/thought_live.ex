defmodule StormfulWeb.Thoughts.ThoughtLive do
  alias Stormful.FlowingThoughts.Wind
  use StormfulWeb, :live_view

  attr :wind, Wind, required: true

  def wind(assigns) do
    ~H"""
    <div class="group">
      <div class="flex items-center gap-3 px-6 py-6 bg-black/70 rounded-lg hover:bg-black/50 transition-all duration-300 overflow-x-auto">
        <div class="flex-shrink-0 flex gap-2 items-center">
          <a target="_blank" href={~p"/my_winds/#{@wind}"}>
            <.icon
              name="hero-bolt"
              class="w-8 h-8 text-blue-400/70 group-hover:text-blue-300 transition-colors"
            />
          </a>

          <div
            id={"wind-clipboard-#{@wind.id}"}
            phx-hook="Clipboard"
            title="Click to copy"
            data-content={@wind.words}
            class="cursor-pointer"
          >
            <.icon
              name="hero-clipboard"
              class="w-8 h-8 text-yellow-400/70 group-hover:text-yellow-300 transition-colors"
            />
          </div>
        </div>

        <p class="text-2xl text-white/90 font-bold leading-relaxed break-normal">
          {@wind.words}
        </p>
      </div>
    </div>
    """
  end
end
