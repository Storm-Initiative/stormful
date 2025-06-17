defmodule StormfulWeb.UserProfileLive do
  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

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
                help_text='Set your timezone so that reminders are scheduled at the right time for you. When AI detects a time like "6:00 PM", it will be scheduled for 6:00 PM in your local timezone.'
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

        <%!-- AI Features --%>
        <div class="bg-white/10 border border-white/20 rounded-lg overflow-hidden shadow-lg mb-6">
          <div class="p-6 border-b border-white/10">
            <h3 class="text-xl font-semibold text-white">
              <.icon name="hero-sparkles" class="h-5 w-5 inline-block mr-2" /> AI-Powered Features
            </h3>
            <p class="mt-1 text-sm text-white/70">Configure how AI assists with your workflow</p>
          </div>

          <%!-- Beta Warning --%>
          <div class="bg-gradient-to-r from-yellow-400/20 to-orange-400/20 border-l-4 border-yellow-400/50 m-4 p-4 rounded-lg">
            <div class="flex items-start">
              <div class="flex-shrink-0">
                <.icon name="hero-exclamation-triangle" class="h-5 w-5 text-yellow-400" />
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-yellow-200">🚀 Experimental AI Features</h3>
                <div class="mt-2 text-sm text-yellow-200">
                  <p>
                    These are cutting-edge AI features still in beta. They're designed to enhance your experience but are experimental.
                  </p>
                  <p class="mt-1">Your feedback helps us improve these features!</p>
                </div>
              </div>
            </div>
          </div>

          <div class="p-6 pt-0">
            <.simple_form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
            >
              <div class="space-y-6">
                <%!-- AI Features --%>
                <div class="border-2 border-white/20 hover:border-white/40 bg-white/5 rounded-lg p-4 mb-4 transition-colors">
                  <div class="flex items-start">
                    <div class="flex h-6 items-center">
                      <.input
                        field={@profile_form[:thought_extraction]}
                        type="checkbox"
                        label=""
                        class="h-5 w-5 text-indigo-400 border-white/30 rounded focus:ring-2 focus:ring-indigo-400 bg-white/10"
                      />
                    </div>
                    <div class="ml-4 flex-1">
                      <label
                        for={@profile_form[:thought_extraction].id}
                        class="block text-lg font-medium text-white mb-2"
                      >
                        <.icon name="hero-light-bulb" class="h-5 w-5 inline-block mr-2" />
                        Thought Extraction & Smart Reminders
                      </label>
                      <p class="text-white/80 text-sm leading-relaxed mb-3">
                        Enable AI to analyze your thoughts and automatically generate intelligent reminders.
                        This feature helps you capture important insights and never miss follow-up actions.
                        System will only try(if you've enabled) to extract thoughts from your journal entries, and never from sensicals.
                      </p>
                      <div class="mt-3 p-3 bg-blue-500/20 border border-blue-400/30 rounded-lg text-sm text-blue-100 flex items-start">
                        <.icon
                          name="hero-information-circle"
                          class="h-5 w-5 flex-shrink-0 text-blue-300 mr-2 mt-0.5"
                        />
                        <div>
                          <p>
                            <strong>How it works:</strong>
                            Your thoughts are securely processed by AI to identify actionable items, deadlines, and important concepts that become smart reminders.
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <:actions>
                <p class="text-sm text-white/60">
                  Changes are saved immediately and take effect for new thoughts.
                </p>
                <.button phx-disable-with="Saving..." class="mt-4">
                  <.icon name="hero-check-circle" class="h-5 w-5 mr-2" /> Save Settings
                </.button>
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

    socket =
      socket
      |> assign(:profile, profile)
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:timezone_options, get_timezone_options())
      |> assign_controlful()

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

  use StormfulWeb.BaseUtil.KeyboardSupport

  defp get_timezone_options do
    # Common timezones that users are likely to need
    common_timezones = Timex.timezones()

    # Sort by display name for better UX
    Enum.sort(common_timezones)
  end
end
