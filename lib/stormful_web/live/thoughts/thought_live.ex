defmodule StormfulWeb.Thoughts.ThoughtLive do
  alias Stormful.FlowingThoughts.Wind
  use StormfulWeb, :live_view

  attr :wind, Wind, required: true

  def thought(assigns) do
    ~H"""
    <div class="group">
      <div class="flex items-center gap-3 px-6 py-4 bg-[#1a1a2e] rounded-lg hover:bg-[#1a1a2e]/80 transition-all duration-300 overflow-x-auto">
        <div class="flex-shrink-0">
          <.icon
            name="hero-bolt"
            class="w-4 h-4 text-blue-400/70 group-hover:text-blue-300 transition-colors"
          />
        </div>

        <p class="text-lg text-white/90 font-medium leading-relaxed break-normal">
          {@wind.words}
        </p>
      </div>
    </div>
    """
  end
end
