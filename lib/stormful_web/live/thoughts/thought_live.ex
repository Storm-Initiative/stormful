defmodule StormfulWeb.Thoughts.ThoughtLive do
  use StormfulWeb, :live_view
  alias Stormful.Brainstorming.Thought

  attr :thought, Thought, required: true

  def thought(assigns) do
    ~H"""
    <div class="flex items-center gap-4 border-white rounded-xl p-2">
      <div class="w-full flex items-center gap-2 p-4 border-2 bg-black">
        <div
          title="This little dot is very very much needed, don't worry about it"
          class={["w-4 h-4 rounded-full", @thought.bg_color]}
        >
        </div>
        <div>
          <.icon name="hero-arrow-right" class="w-6 h-6" />
        </div>
        <div class="text-xl font-bold w-full overflow-x-auto">
          <%= @thought.words %>
        </div>
      </div>
      <div class="flex gap-2">
        <!-- <.mini_button -->
        <!--   title="Create a todo from this" -->
        <!--   phx-click="create-todo-from-me" -->
        <!--   phx-value-id={@thought.id} -->
        <!-- > -->
        <!--   <.icon name="hero-exclamation-circle" /> -->
        <!-- </.mini_button> -->
        <!-- <.mini_button title="Archive"> -->
        <!--   <.icon name="hero-archive-box-arrow-down" /> -->
        <!-- </.mini_button> -->
      </div>
    </div>
    """
  end

  # INFO: putting this here so that tailwind would pick it
end
