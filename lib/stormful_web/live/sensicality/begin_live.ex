defmodule StormfulWeb.Sensicality.BeginLive do
  alias Stormful.Sensicality
  alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view

  @playful_descriptions [
    "Ready to unleash a storm of ideas? Give your Sensical a name worthy of legend—or at least something you’ll remember after a coffee break ☕️.",
    "Every great storm starts with a single cloud. Name your Sensical and let the thunder roll! ⚡️",
    "Don’t worry, you can’t break the weather. But you can make it memorable! Name your Sensical.",
    "This is where the magic happens. Or at least where the naming happens. ✨",
    "Give your Sensical a name. Bonus points if it makes you giggle in a meeting.",
    "Naming things is hard. But at least it’s not raining… yet! 🌧️",
    "Your Sensical’s name could be legendary. Or totally random. We won’t judge.",
    "The forecast calls for creativity. Name your Sensical and let’s get breezy! 🌬️",
    "Go on, give it a name. Even if it’s just ‘Untitled Storm #42’.",
    "If you name it, it will storm. Probably. Maybe. Give it a try!",
    "Don’t overthink it. Unless you want to. Then overthink away!",
    "This is your moment. Make it punny, make it sunny, just make it Sensical!",
    "A Sensical by any other name would storm as sweet. Shakespeare probably. 🌩️",
    "Give your Sensical a name that would make the weather jealous.",
    "Let’s get this brainstorm started—with a name!",
    "You’re one name away from greatness. Or at least a cool new Sensical.",
    "The only wrong name is no name at all. Unless it’s ‘No Name’. That’s fine too.",
    "Your Sensical’s adventure begins with a name. Choose wisely—or wildly!",
    "Make it mysterious. Make it hilarious. Just make it yours.",
    "If you can’t think of a name, just mash your keyboard. We support creative chaos!"
  ]

  def mount(_params, _session, socket) do
    description = Enum.random(@playful_descriptions)

    {:ok,
     socket
     |> assign_sensical_form(Sensicality.change_sensical(%Sensical{}))
     |> assign(:playful_description, description),
     layout: {StormfulWeb.Layouts, :sensicality_center}}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="text-center flex flex-col items-center gap-4 animate-fade-in w-full">
        <.back navigate={~p"/into-the-storm"}>
          Go back
        </.back>

        <div class="mt-8 transform hover:scale-102 transition-all">
          <.cool_header little_name="It all starts with" big_name="A new Sensical ⛈" />
        </div>
        <div class="mt-2 max-w-md text-purple-300 text-lg italic">
          {@playful_description}
        </div>
      </div>

      <.form
        for={@sensical_form}
        phx-submit="create-sensical"
        phx-change="change-sensical"
        class="mt-8 max-w-lg mx-auto bg-purple-900/10 backdrop-blur-sm rounded-lg p-6 shadow-xl border border-purple-500/20"
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
          <.button class="mt-6 px-8 py-3 bg-purple-700 hover:bg-purple-600 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-purple-500/30">
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
end
