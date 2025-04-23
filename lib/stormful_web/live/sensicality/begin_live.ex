defmodule StormfulWeb.Sensicality.BeginLive do
  alias Stormful.Sensicality
  alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_sensical_form(Sensicality.change_sensical(%Sensical{}))
     |> assign_controlful()}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="text-center flex flex-col items-center gap-4 animate-fade-in">
        <.back navigate={~p"/into-the-storm"} class="hover:scale-105 transition-transform">
          Go back
        </.back>

        <div class="mt-8 transform hover:scale-102 transition-all">
          <.cool_header
            little_name="It all starts with"
            big_name="A new Sensical ⛈"
            class="animate-shine bg-gradient-to-r from-yellow-400 via-indigo-500 to-yellow-400 bg-[length:200%] bg-clip-text text-transparent"
          />
        </div>
      </div>

      <.form
        for={@sensical_form}
        phx-submit="create-sensical"
        phx-change="change-sensical"
        class="mt-8 max-w-lg mx-auto bg-indigo-900/10 backdrop-blur-sm rounded-lg p-6 shadow-xl border border-indigo-500/20"
      >
        <div class="text-lg">
          <.input
            type="message_area"
            field={@sensical_form[:title]}
            label="Let's start by naming it, shall we?"
            class="transition-all focus:ring-2 focus:ring-yellow-400/50"
          />
        </div>
        <div class="flex w-full justify-center">
          <.button class="mt-6 px-8 py-3 bg-indigo-700 hover:bg-indigo-600 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-indigo-500/30">
            <span class="flex items-center gap-2">
              Yea <.icon name="hero-sparkles" class="w-5 h-5 text-yellow-400 animate-pulse" />
            </span>
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("change-sensical", %{"sensical" => %{"title" => title}}, socket) do
    socket = socket |> assign_sensical_form(Sensicality.change_sensical(%Sensical{title: title}))

    {:noreply, socket}
  end

  def handle_event("create-sensical", %{"sensical" => %{"title" => title}}, socket) do
    # one last time to update the sensical <3
    current_user = socket.assigns.current_user

    sensical = %{title: title, user_id: current_user.id}

    socket =
      case Sensicality.create_sensical(sensical) do
        {:ok, sensical} ->
          push_navigate(socket, to: ~p"/sensicality/#{sensical.id}")
          |> put_flash(:info, "Created successfully ⚡")

        {:error, changeset} ->
          socket |> assign(:sensical_form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def assign_sensical_form(socket, changeset) do
    socket |> assign(:sensical_form, to_form(changeset))
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
