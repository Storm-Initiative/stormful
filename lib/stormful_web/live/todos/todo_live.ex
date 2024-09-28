defmodule StormfulWeb.Todos.TodoLive do
  alias Stormful.TaskManagement.Todo
  alias StormfulWeb.Todos
  use StormfulWeb, :live_view

  attr(:todo, Todo, required: true)

  def todo(assigns) do
    ~H"""
    <div class="flex p-2 rounded-xl bg-slate-900">
      <p class="min-w-sm mr-1"><.icon name="hero-arrow-turn-down-right" /></p>
      <p
        class={["text-nowrap overflow-x-scroll flex-0", @todo.completed_at != nil && "line-through"]}
        phx-click="complete-todo"
        phx-value-todo-id={@todo.id}
        phx-target="todos-general"
      >
        &nbsp; <%= @todo.title %> <%= @todo.completed_at != nil || "heey" %>
      </p>
    </div>
    """
  end

  @impl true
  def handle_event("complete-todo", _, socket) do
    send_update(StormfulWeb.Todos.PopupLive, id: socket.assigns.todo.id)

    {:noreply, socket}
  end
end
