defmodule StormfulWeb.Todos.PopupLive do
  alias StormfulWeb.Todos
  alias Stormful.TaskManagement
  use StormfulWeb, :live_component
  use Phoenix.Component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(open: false)
     |> stream(:todos, TaskManagement.list_todos(socket.assigns.current_user), reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="absolute w-full lg:max-w-lg xl:max-w-3xl top-4 left-4" id="todos">
      <div class="flex w-full items-center relative">
        <p>Todos</p>&nbsp;<span class="absolute top-2 left-12"><.icon name="hero-arrow-turn-right-down" /></span>
      </div>
      <div class="absolute top-8 p-4 bg-purple-800 rounded-xl w-full lg:max-w-lg xl:max-w-3xl border-black border-4">
        <h3 class="text-xl font-bold underline">Todos</h3>
        <div phx-update="stream" id="todos" class="mt-2 flex flex-col gap-2">
          <div :for={{dom_id, todo} <- @streams.todos} dom_id={dom_id}>
            <Todos.TodoLive.todo todo={todo} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  # @impl true
  # def handle_event("complete-todo", _, socket) do
  #   case TaskManagement.complete_todo(socket.assigns.todo) do
  #     {:ok, todo} ->
  #       {:noreply,
  #        socket |> put_flash(:info, "Todo completed successfully") |> assign(:todo, todo)}

  #     {:error, _changeset} ->
  #       {:noreply, socket |> put_flash(:error, "Something went horribly wrong")}
  #   end
  # end
end
