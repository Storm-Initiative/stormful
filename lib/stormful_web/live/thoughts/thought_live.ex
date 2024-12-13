defmodule StormfulWeb.Thoughts.ThoughtLive do
  use StormfulWeb, :live_view
  alias Stormful.Brainstorming.Thought

  attr :thought, Thought, required: true

  def thought(assigns) do
    ~H"""
    <div class="flex items-center gap-4 border-white p-4 border-2 bg-black rounded-sm overflow-x-auto">
      <div
        title="This little dot is very very much needed, don't worry about it"
        class={["w-4 h-4 rounded-full", @thought.bg_color]}
      >
      </div>
      <div class="flex items-center justify-center p-1">
        <.icon name="hero-arrow-right" class="w-6 h-6" />
      </div>
      <div class="text-xl font-bold w-full overflow-x-auto">
        <%= @thought.words %>
      </div>
    </div>
    """
  end

  # INFO: putting this here so that tailwind would pick it
end
