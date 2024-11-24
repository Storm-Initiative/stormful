defmodule StormfulWeb.Sensicality.TheSensicalLive do
  alias Stormful.Brainstorming.Thought
  alias Stormful.Brainstorming

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    sensical = Sensicality.get_sensical!(current_user.id, params["sensical_id"])
    thoughts_of_that_sensical = Brainstorming.list_thoughts_for_a_sensical(sensical.id)

    {:ok,
     socket
     |> assign_controlful()
     |> assign(sensical: sensical)
     |> stream(:thoughts, thoughts_of_that_sensical)
     |> assign_clear_thought_form()}
  end

  @impl true
  def handle_event("change-thought", %{"thought" => %{"words" => words}}, socket) do
    {:noreply,
     socket |> assign_thought_form(Brainstorming.change_thought(%Thought{words: words}))}
  end

  @impl true
  def handle_event("create-thought", %{"thought" => %{"words" => words}}, socket) do
    current_user = socket.assigns.current_user
    sensical = socket.assigns.sensical

    case Brainstorming.create_thought(%{
           words: words,
           bg_color: socket.assigns.submit_color,
           user_id: current_user.id,
           sensical_id: sensical.id
         }) do
      {:ok, thought} ->
        {:noreply,
         socket
         |> stream_insert(:thoughts, thought)
         |> assign_clear_thought_form()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, thought_form: to_form(changeset))}
    end
  end

  defp assign_thought_form(socket, changeset) do
    colors = Thought.colors()

    socket
    |> assign(:thought_form, to_form(changeset))
    |> assign(:submit_color, Enum.random(colors))
  end

  defp assign_clear_thought_form(socket) do
    socket |> assign_thought_form(Brainstorming.change_thought(%Thought{}))
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
