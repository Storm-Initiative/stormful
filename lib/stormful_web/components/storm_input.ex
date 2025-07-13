defmodule StormfulWeb.StormInput do
  @moduledoc false

  use Phoenix.LiveComponent
  import StormfulWeb.CoreComponents
  alias Stormful.FlowingThoughts
  alias Stormful.FlowingThoughts.Wind

  require Logger

  def render(assigns) do
    ~H"""
    <div class="bg-black/20 backdrop-blur-sm border border-white/10 rounded-lg p-4 text-xl">
      <div class="max-w-7xl mx-auto">
        <.form
          phx-target={@myself}
          for={@wind_form}
          phx-submit="save"
          phx-change="change_wind"
          class="flex flex-col gap-4 items-center"
        >
          <div class="flex-grow w-full text-2xl">
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
            class="px-6 py-3 bg-white/10 hover:bg-white/20 border border-white/20 hover:border-white/30 
                   text-white font-semibold rounded-lg transition-all duration-300 
                   flex items-center gap-2 hover:scale-105"
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
    # Determine if we're in a sensical or journal context
    wind_attrs = %{
      words: words,
      user_id: socket.assigns.current_user.id
    }

    wind_attrs =
      cond do
        Map.has_key?(socket.assigns, :sensical) ->
          Map.put(wind_attrs, :sensical_id, socket.assigns.sensical.id)

        Map.has_key?(socket.assigns, :journal) ->
          Map.put(wind_attrs, :journal_id, socket.assigns.journal.id)

        true ->
          # Fallback - this shouldn't happen but just in case
          wind_attrs
      end

    case FlowingThoughts.create_wind(socket.assigns.current_user, wind_attrs) do
      {:ok, _wind} ->
        {:noreply, socket |> assign_clear_wind_form()}

      {:error, changeset} ->
        {:noreply, socket |> assign_wind_form(changeset)}
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
