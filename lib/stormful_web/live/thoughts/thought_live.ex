defmodule StormfulWeb.Thoughts.ThoughtLive do
  alias Stormful.FlowingThoughts.Wind
  use StormfulWeb, :live_view

  attr :wind, Wind, required: true

  def wind(assigns) do
    ~H"""
    <div class="group">
      <div class="flex items-center gap-3 px-6 py-6 bg-black/70 rounded-lg hover:bg-black/50 transition-all duration-300 overflow-x-auto">
        <div class="flex-shrink-0">
          <.icon
            name="hero-bolt"
            class="w-10 h-10 text-blue-400/70 group-hover:text-blue-300 transition-colors"
          />
        </div>

        <p class="text-2xl text-white/90 font-bold leading-relaxed break-normal">
          {@wind.words}
        </p>
      </div>
    </div>
    """
  end
end
