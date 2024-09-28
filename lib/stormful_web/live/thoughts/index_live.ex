defmodule StormfulWeb.Thoughts.IndexLive do
  alias Stormful.TaskManagement
  use StormfulWeb, :live_view

  alias Stormful.Brainstorming
  alias Stormful.Brainstorming.Thought

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:todo_modal_open, false)
     |> assign(:hide_mode, true)
     |> assign_clear_thought_form()}
  end

  defp stream_thoughts(socket) do
    thoughts = Brainstorming.list_thoughts()

    socket |> stream(:thoughts, thoughts, reset: true)
  end

  @impl true
  def handle_event("create-thought", %{"thought" => %{"words" => words}}, socket) do
    case words do
      "up up down right" ->
        {:noreply,
         socket
         |> put_flash(:info, "(((;")
         |> assign_clear_thought_form()}

      "clear" ->
        {archived_amount, _} = Brainstorming.archive_all()

        {:noreply,
         socket
         |> put_flash(:info, "Archived #{archived_amount} thoughts")
         |> assign_clear_thought_form()
         |> stream(:thoughts, Brainstorming.list_thoughts(), reset: true)}

      "load archives" ->
        {:noreply,
         socket
         |> put_flash(:info, "Loaded the archives")
         |> assign_clear_thought_form()
         |> stream(:thoughts, Brainstorming.list_archived_included_thoughts(), reset: true)}

      "todos" ->
        {:noreply,
         socket
         |> put_flash(:info, "Loading the todos")
         |> assign(:todo_modal_open, true)
         |> assign_clear_thought_form()}

      "close" ->
        {:noreply,
         socket
         |> put_flash(:info, "Popups closed")
         |> assign(:todo_modal_open, false)
         |> assign_clear_thought_form()}

      "hide" ->
        {:noreply,
         socket
         |> put_flash(:info, "Hidden mode on")
         |> assign(:hide_mode, true)
         |> assign_clear_thought_form()}

      "show" ->
        {:noreply,
         socket
         |> put_flash(:info, "Hidden mode off")
         |> assign(:hide_mode, false)
         |> assign_clear_thought_form()
         |> stream_thoughts()}

      _ ->
        case Brainstorming.create_thought(%{words: words, bg_color: socket.assigns.submit_color}) do
          {:ok, thought} ->
            if socket.assigns.hide_mode do
              {:noreply,
               socket
               |> assign_clear_thought_form()}
            else
              {:noreply,
               socket
               |> stream_insert(:thoughts, thought, at: 0)
               |> assign_clear_thought_form()}
            end

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, thought_form: to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("change-thought", %{"thought" => %{"words" => words}}, socket) do
    socket =
      socket
      |> assign_thought_form(Brainstorming.change_thought(%Thought{words: words}))

    {:noreply, socket}
  end

  @impl true
  def handle_event("create-todo-from-me", %{"id" => id}, socket) do
    {:ok, created_todo} = TaskManagement.create_todo_from_thought(id)

    if socket.assigns.todo_modal_open do
      {:noreply, socket |> stream_insert(:todos, created_todo), 0}
    else
      {:noreply, socket}
    end
  end

  defp assign_thought_form(socket, changeset) do
    colors = Thought.colors()

    assign(socket, :thought_form, to_form(changeset))
    |> assign(:submit_color, Enum.random(colors))
  end

  defp assign_clear_thought_form(socket) do
    socket |> assign_thought_form(Brainstorming.change_thought(%Thought{}))
  end
end
