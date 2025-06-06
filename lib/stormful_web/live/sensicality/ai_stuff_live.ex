defmodule StormfulWeb.Sensicality.AiStuffLive do
  alias Stormful.FlowingThoughts
  alias StormfulWeb.Layouts

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    sensical = Sensicality.get_sensical!(current_user.id, params["sensical_id"])

    FlowingThoughts.subscribe_to_sensical(sensical)

    {:ok,
     socket
     |> assign(:sensical, sensical)
     |> assign(:raw_summary, Phoenix.HTML.raw(sensical.summary)), layout: {Layouts, :sensicality}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, action, _params) do
    representable_action_name = Atom.to_string(action) |> String.replace("_", "-")

    current_tab_title =
      representable_action_name |> String.replace("-", " ") |> String.capitalize()

    little_title_label =
      Enum.random([
        "currently @",
        "@",
        "right @",
        "now you are @",
        "you are viewing the",
        "you seem to be hangin out @",
        "hey, this is",
        "how's the weather at",
        "no way, you are at",
        "you know your stuff if you are @",
        "hi from",
        "this is",
        "hmm, you seem to be @"
      ])

    socket
    |> assign_neededs_for_action(action)
    |> assign(:current_action, action)
    |> assign(:current_tab, representable_action_name)
    |> assign(:current_tab_title, current_tab_title)
    |> assign(:little_title_label, little_title_label)
  end

  defp assign_neededs_for_action(socket, _) do
    socket
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="p-8">
        <style>
          summary {
            list-style: none;
          }
        </style>
        <.button phx-click="summarize">
          Get a nice summary
        </.button>
        <div class="mt-8 flex flex-col gap-8 p-4 bg-black border-2 border-white">
          <h2 class="text-2xl">The summary</h2>
          <div class="text-lg font-medium">
            {@raw_summary}
          </div>
        </div>
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
