defmodule StormfulWeb.Sensicality.LiveComponents.Todos do
  @moduledoc false
  import StormfulWeb.CoreComponents

  alias Stormful.TaskManagement.Todo
  alias Stormful.Planning

  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{todo: todo}, socket) do
    {:ok,
     stream_insert(socket, :todos, todo)
     |> push_event("scroll-to-latest-wind", %{})}
  end

  @impl true
  def update(assigns, socket) do
    sensical = assigns.sensical
    current_user = assigns.current_user

    plan = Planning.get_preferred_plan_of_sensical!(current_user.id, sensical.id)

    {:ok, socket |> assign(:current_plan, plan) |> stream(:todos, plan.todos)}
  end

  attr :todo, Todo

  def todo(assigns) do
    ~H"""
    <div class="group">
      <div class="flex items-center gap-3 px-6 py-6 bg-black/70 rounded-lg hover:bg-black/50 transition-all duration-300 overflow-x-auto">
        <div class="flex-shrink-0">
          <div class={
            [
              "rounded-full flex items-center justify-center transition-colors",
              # Increased size to accommodate both states
              "w-10 h-10",
              @todo.completed_at && "bg-blue-400/70 group-hover:bg-blue-300",
              !@todo.completed_at &&
                "border-2 border-blue-400/70 group-hover:border-blue-300 group-hover:cursor-pointer"
            ]
          }>
            <%= if @todo.completed_at do %>
              <.icon
                name="hero-bolt"
                class={[
                  "w-6 h-6 transition-colors text-white"
                ]}
              />
            <% end %>
          </div>
        </div>

        <p class={[
          "text-2xl font-bold leading-relaxed break-normal",
          if @todo.completed_at do
            "text-white/50 line-through"
          else
            "text-white/90"
          end
        ]}>
          {@todo.title}
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="p-8 pt-0 flex flex-col gap-4" id="todos" phx-hook="WindScroller" phx-update="stream">
        <div :for={{dom_id, todo} <- @streams.todos} dom_id={dom_id} id={dom_id}>
          <.todo todo={todo} />
        </div>
      </div>
    </div>
    """
  end
end
