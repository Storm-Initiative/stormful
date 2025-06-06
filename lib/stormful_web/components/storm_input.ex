defmodule StormfulWeb.StormInput do
  @moduledoc false

  use Phoenix.LiveComponent
  import StormfulWeb.CoreComponents
  alias Stormful.Attention
  alias Stormful.TaskManagement
  alias Stormful.FlowingThoughts
  alias Stormful.FlowingThoughts.Wind

  def render(assigns) do
    ~H"""
    <div class="bg-indigo-900 p-4 text-xl m-4">
      <div class="max-w-7xl mx-auto">
        <.form
          phx-target={@myself}
          for={@wind_form}
          phx-submit="save"
          phx-change="change_wind"
          class="flex flex-col sm:flex-row gap-4 items-center"
        >
          <div class="flex-grow text-2xl">
            <.input
              type="message_area"
              field={@wind_form[:words]}
              placeholder="write your thoughts here"
              label="The Storm Input"
              label_centered={true}
            />
          </div>
          <.button
            type="submit"
            class="px-6 py-3 bg-indigo-500 hover:bg-indigo-400 text-white font-semibold
                   rounded-lg transition-colors flex items-center gap-2"
          >
            <span>⚡</span>
            <span>Enter</span>
          </.button>
        </.form>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign_clear_wind_form()}
  end

  def handle_event("change_wind", %{"wind" => %{"words" => words}}, socket) do
    {:noreply, socket |> assign_wind_form(FlowingThoughts.change_wind(%Wind{words: words}))}
  end

  def handle_event(
        "save",
        %{"wind" => %{"words" => words}},
        socket
      ) do
    sensical = socket.assigns.sensical

    first_of_words = String.first(words)

    case first_of_words do
      "?" ->
        [_head | tail] = String.split(words, "", trim: true)
        meaty_part = tail |> Enum.join("")

        case TaskManagement.create_todo_for_sensicals_preferred_plan(
               socket.assigns.current_user.id,
               sensical.id,
               meaty_part
             ) do
          {:ok, _todo} ->
            {:noreply, socket |> assign_clear_wind_form()}

          {:error, changeset} ->
            {:noreply, socket |> assign_wind_form(changeset)}
        end

      "!" ->
        [_head | tail] = String.split(words, "", trim: true)
        meaty_part = tail |> Enum.join("")

        case Attention.create_headsup(
               socket.assigns.current_user.id,
               sensical.id,
               meaty_part
             ) do
          {:ok, _headsup} ->
            {:noreply, socket |> assign_clear_wind_form()}

          {:error, changeset} ->
            {:noreply, socket |> assign_wind_form(changeset)}
        end

      _ ->
        case FlowingThoughts.create_wind(%{
               sensical_id: sensical.id,
               words: words,
               user_id: socket.assigns.current_user.id
             }) do
          {:ok, _wind} ->
            {:noreply, socket |> assign_clear_wind_form()}

          {:error, changeset} ->
            {:noreply, socket |> assign_wind_form(changeset)}
        end
    end
  end

  defp assign_wind_form(socket, changeset) do
    socket
    |> assign(:wind_form, to_form(changeset))
  end

  defp assign_clear_wind_form(socket) do
    socket |> assign_wind_form(FlowingThoughts.change_wind(%Wind{}))
  end
end
