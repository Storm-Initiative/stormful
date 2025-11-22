defmodule StormfulWeb.UserProfileLive do
  use StormfulWeb, :live_view

  alias Stormful.ProfileManagement
  import StormfulWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account and preferences</:subtitle>
    </.header>

    <div class="max-w-4xl mx-auto">
      <%!-- Settings Navigation --%>
      <div class="bg-white/10 backdrop-blur-sm shadow rounded-lg mb-8">
        <div class="border-b border-white/20">
          <nav class="-mb-px flex space-x-8 px-6">
            <.link
              navigate={~p"/users/settings"}
              class="py-4 px-1 border-b-2 border-transparent font-medium text-sm text-white/70 hover:text-white hover:border-white/30 whitespace-nowrap"
            >
              Account Security
            </.link>
            <button
              type="button"
              class="py-4 px-1 border-b-2 font-medium text-sm whitespace-nowrap border-white text-white"
            >
              Profile
              <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-400 text-yellow-900">
                Beta
              </span>
            </button>
            <.link
              navigate={~p"/users/outside"}
              class="py-4 px-1 border-b-2 border-transparent font-medium text-sm text-white/70 hover:text-white hover:border-white/30 whitespace-nowrap"
            >
              Outside
              <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-400 text-yellow-900">
                Beta
              </span>
            </.link>
          </nav>
        </div>
      </div>

      <%!-- Profile Content --%>
      <div class="space-y-6">
        <%!-- Timezone Settings - Above all experimental features --%>
        <div class="bg-white/10 border border-white/20 rounded-lg overflow-hidden shadow-lg mb-6">
          <div class="p-6 border-b border-white/10">
            <h3 class="text-xl font-semibold text-white">
              <.icon name="hero-globe-europe-africa-solid" class="h-5 w-5 inline-block mr-2" />
              Timezone Settings
            </h3>
            <p class="mt-1 text-sm text-white/70">Configure your timezone for accurate reminders</p>
          </div>
          <div class="p-6">
            <.simple_form
              for={@profile_form}
              id="timezone_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
            >
              <.input
                field={@profile_form[:timezone]}
                type="select"
                options={@timezone_options}
                prompt="Select your timezone"
                label="Your Timezone"
                help_text="Set your timezone so that reminders are scheduled at the right time for you"
                class="bg-white/5 border-white/10 text-white"
              />

              <:actions>
                <p class="text-sm text-white/60">
                  Your timezone setting affects all future reminders.
                </p>
                <.button phx-disable-with="Saving..." class="mt-4">
                  <.icon name="hero-check-circle" class="h-5 w-5 mr-2" /> Save Timezone
                </.button>
              </:actions>
            </.simple_form>
          </div>
        </div>

        <%!-- Greeting Phrase Settings --%>
        <div class="bg-white/10 border border-white/20 rounded-lg overflow-hidden shadow-lg mb-6">
          <div class="p-6 border-b border-white/10">
            <h3 class="text-xl font-semibold text-white">
              <.icon name="hero-chat-bubble-left-ellipsis" class="h-5 w-5 inline-block mr-2" />
              General
            </h3>
            <p class="mt-1 text-sm text-white/70">
              Set a personal greeting that appears in your journal, and the landing to the root logic.
            </p>
          </div>
          <div class="p-6">
            <.simple_form
              for={@profile_form}
              id="greeting_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
            >
              <.input
                field={@profile_form[:greeting_phrase]}
                type="text"
                label="Your Greeting Phrase"
                placeholder="Good morning, ready to storm the day!"
                help_text="This greeting will appear at the top of your journal. Keep it short and inspiring!"
                class="bg-white/5 border-white/10 text-white"
                maxlength="100"
              />

              <.input
                field={@profile_form[:lands_initially]}
                type="select"
                options={@landing_options}
                prompt="Select your landing preference"
                label="Landing initially"
                help_text="Set where you want to be landed upon going to the root of the app"
                class="bg-white/5 border-white/10 text-white"
                required
              />

              <:actions>
                <div class="w-full flex justify-end">
                  <.button phx-disable-with="Saving..." class="mt-4">
                    <.icon name="hero-check-circle" class="h-5 w-5 mr-2" /> Save
                  </.button>
                </div>
              </:actions>
            </.simple_form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    profile = ProfileManagement.get_or_create_user_profile(user)

    profile_changeset = ProfileManagement.change_user_profile(profile)

    landing_options = [
      Journal: :journal,
      "Latest Sensical": :latest_sensical
    ]

    socket =
      socket
      |> assign(:profile, profile)
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:timezone_options, get_timezone_options())
      |> assign(:landing_options, landing_options)

    {:ok, socket}
  end

  def handle_event("validate_profile", %{"profile" => profile_params}, socket) do
    profile_form =
      socket.assigns.profile
      |> ProfileManagement.change_user_profile(profile_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"profile" => profile_params}, socket) do
    case ProfileManagement.update_user_profile(socket.assigns.profile, profile_params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile settings updated successfully!")
         |> assign(:profile, profile)
         |> assign(:profile_form, to_form(ProfileManagement.change_user_profile(profile)))}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  defp get_timezone_options do
    # Common timezones that users are likely to need
    common_timezones = Timex.timezones()

    # Sort by display name for better UX
    Enum.sort(common_timezones)
  end
end
