defmodule StormfulWeb.StormInput do
  use Phoenix.LiveComponent
  import StormfulWeb.CoreComponents
  alias Stormful.FlowingThoughts
  alias Stormful.FlowingThoughts.Wind

  def render(assigns) do
    ~H"""
    <div class="fixed bottom-0 left-0 right-0 bg-indigo-900 z-[1] border-t border-indigo-700 p-4 text-xl">
      <div class="max-w-7xl mx-auto">
        <.form
          phx-target={@myself}
          for={@wind_form}
          phx-submit="save"
          phx-change="change_wind"
          class="flex gap-4 items-center"
        >
          <div class="flex-grow text-2xl">
            <.input
              type="message_area"
              field={@wind_form[:words]}
              placeholder="What do you mean, 'placeholder'?"
              label="The glorious thought input"
              label_centered={true}
            />
          </div>
          <.button
            type="submit"
            class="px-6 py-3 bg-indigo-500 hover:bg-indigo-400 text-white font-semibold 
                   rounded-lg transition-colors flex items-center gap-2"
          >
            <span>⚡</span>
            <span>Strike!</span>
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

  def handle_event("save", %{"wind" => %{"words" => words}}, socket) do
    sensical = socket.assigns.sensical

    with {:ok, _wind} <-
           FlowingThoughts.create_wind(%{
             sensical_id: sensical.id,
             words: words,
             user_id: socket.assigns.current_user.id
           }) do
      {:noreply, socket |> assign_clear_wind_form()}
    else
      {:error, changeset} -> {:noreply, socket |> assign_wind_form(changeset)}
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
