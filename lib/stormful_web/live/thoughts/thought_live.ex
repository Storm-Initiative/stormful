defmodule StormfulWeb.Thoughts.ThoughtLive do
  use StormfulWeb, :live_view
  alias Stormful.Brainstorming.Thought

  attr :thought, Thought, required: true

  def thought(assigns) do
    ~H"""
    <div class={["flex items-center gap-4 border-white rounded-xl p-2", @thought.bg_color]}>
      <div class="w-full text-center overflow-x-scroll">
        <%= @thought.words %>
      </div>
      <div class="flex gap-2">
        <.mini_button
          title="Create a todo from this"
          phx-click="create-todo-from-me"
          phx-value-id={@thought.id}
        >
          <.icon name="hero-exclamation-circle" />
        </.mini_button>
        <.mini_button title="Archive">
          <.icon name="hero-archive-box-arrow-down" />
        </.mini_button>
      </div>
    </div>
    """
  end

  # INFO: putting this here so that tailwind would pick it
end
