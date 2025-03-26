defmodule StormfulWeb.Sensicality.LiveComponents.AiStuff do
  @moduledoc false

  import StormfulWeb.CoreComponents
  alias Stormful.Sensicality

  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    current_user = assigns.current_user
    sensical = assigns.sensical

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:sensical, sensical)
     |> assign(:raw_summary, Phoenix.HTML.raw(sensical.summary))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-8">
      <.button phx-click="summarize" phx-target={@myself}>
        Get a nice summary
      </.button>
      <div class="mt-8 flex flex-col gap-4">
        <h2 class="text-2xl">The summary</h2>
        {@raw_summary}
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("summarize", _, socket) do
    current_user = socket.assigns.current_user
    sensical = socket.assigns.sensical

    new_summary = Sensicality.summarize_sensical(current_user.id, sensical.id)
    {:noreply, socket |> assign(:raw_summary, Phoenix.HTML.raw(new_summary))}
  end
end
