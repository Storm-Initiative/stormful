defmodule StormfulWeb.Sensicality.Plans.PlanContainerLive do
  alias Stormful.TaskManagement
  alias Stormful.TaskManagement.Todo
  use StormfulWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:plan, assigns.plan)
     |> assign(:current_user, assigns.current_user)
     |> stream(:todos, assigns.plan.todos)
     |> assign_todo_form(TaskManagement.change_todo(%Todo{}))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-col gap-0">
        <p class="text-center text-sm font-bold">Let's do this</p>
        <h2 class="text-center font-bold text-2xl underline"><%= @plan.title %></h2>
      </div>
      <.form for={@todo_form} phx-submit="create-todo" phx-change="change-todo" phx-target={@myself}>
        <.input
          type="message_area"
          field={@todo_form[:title]}
          label="Create a todo"
          placeholder="i may not look like it but i am an input -_-"
        />
        <div class="flex w-full justify-center">
          <.button class="mt-4 px-6 bg-indigo-700">Alright![enter]</.button>
        </div>
      </.form>

      <div class="flex flex-col gap-2 mt-4 border-2 p-4">
        <h3 class="flex justify-center items-center gap-2 underline font-bold text-xl mb-4">
          <span class="mt-4">
            <.icon name="hero-arrow-turn-left-down" class="w-8 h-8" />
          </span>
          <span>Here are your todos</span>
          <span class="mt-4">
            <.icon name="hero-arrow-turn-right-down" class="w-8 h-8" />
          </span>
        </h3>
        <div class="flex flex-col gap-2" id="plan-todos" phx-update="stream">
          <.todo :for={{dom_id, todo} <- @streams.todos} id={dom_id} todo={todo} myself={@myself} />
        </div>
        <p class="text-center text-xl font-bold">⚡ Done and done ✊</p>
      </div>
    </div>
    """
  end

  attr :todo, Todo, required: true
  attr :id, :string, required: true
  attr :myself, :any, required: true

  def todo(assigns) do
    ~H"""
    <div id={@id} title={@todo.completed_at && "Completed @ #{@todo.completed_at} UTC"}>
      <div class={[
        "flex bg-black p-2 border-2 rounded-sm gap-2 overflow-x-auto items-center",
        @todo.completed_at && ["bg-green-800 border-black"],
        !@todo.completed_at && ["bg-black border-white"]
      ]}>
        <span>
          <%= if @todo.completed_at do %>
            <button
              phx-click="mark-todo-complete"
              phx-value-todo-id={@todo.id}
              phx-value-intention="uncomplete"
              phx-target={@myself}
            >
              <.icon name="hero-check-circle" class="w-8 h-8" />
            </button>
          <% else %>
            <button
              phx-click="mark-todo-complete"
              phx-value-todo-id={@todo.id}
              phx-value-intention="complete"
              phx-target={@myself}
            >
              <.icon name="hero-exclamation-circle" class="w-8 h-8" />
            </button>
          <% end %>
        </span>
        <span class={[!@todo.completed_at && "font-semibold", @todo.completed_at && "text-sm"]}>
          <%= @todo.title %>
        </span>
      </div>
      <div class="flex justify-center items-center pt-2">
        <.icon name="hero-arrow-long-down" class="w-8 h-8" />
      </div>
    </div>
    """
  end

  def handle_event(
        "mark-todo-complete",
        %{"todo-id" => todo_id, "intention" => intention},
        socket
      ) do
    current_user = socket.assigns.current_user

    socket =
      case intention do
        "complete" ->
          {:ok, marked_todo} = TaskManagement.mark_todo(current_user.id, todo_id, true)
          socket |> stream_insert(:todos, marked_todo)

        "uncomplete" ->
          {:ok, marked_todo} = TaskManagement.mark_todo(current_user.id, todo_id, false)
          socket |> stream_insert(:todos, marked_todo)
      end

    {:noreply, socket}
  end

  def handle_event("change-todo", %{"todo" => %{"title" => title}}, socket) do
    socket = socket |> assign_todo_form(TaskManagement.change_todo(%Todo{title: title}))

    {:noreply, socket}
  end

  def handle_event("create-todo", %{"todo" => %{"title" => title}}, socket) do
    # one last time to update the sensical <3
    current_user = socket.assigns.current_user
    todo = %{title: title, plan_id: socket.assigns.plan.id, user_id: current_user.id}

    socket =
      case TaskManagement.create_todo(todo) do
        {:ok, todo} ->
          socket
          |> stream_insert(:todos, todo)
          |> assign_todo_form(TaskManagement.change_todo(%Todo{}))
          |> put_flash(:info, "Todo has been successfully ⚡")

        {:error, changeset} ->
          socket
          |> assign(:todo_form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def assign_todo_form(socket, changeset) do
    socket |> assign(:todo_form, to_form(changeset))
  end
end
