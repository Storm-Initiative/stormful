defmodule StormfulWeb.UserProfileLive do
  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

  alias Stormful.ProfileManagement

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
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm whitespace-nowrap",
                "border-white text-white"
              ]}
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
        <div class="bg-white/10 backdrop-blur-sm shadow-lg rounded-xl border border-white/20">
          <div class="px-6 py-5 border-b border-white/20">
            <h3 class="text-xl font-semibold text-white">🌍 Timezone Settings</h3>
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
              />

              <:actions>
                <div class="text-sm text-white/60">
                  Your timezone setting affects all future reminders.
                </div>
                <.button
                  phx-disable-with="Saving..."
                  class="bg-white/20 hover:bg-white/30 text-white font-medium py-2 px-6 rounded-lg shadow-sm transition-colors border border-white/30 backdrop-blur-sm"
                >
                  💾 Save Timezone
                </.button>
              </:actions>
            </.simple_form>
          </div>
        </div>

        <%!-- AI Features --%>
        <div class="bg-white/10 backdrop-blur-sm shadow-lg rounded-xl border border-white/20">
          <div class="px-6 py-5 border-b border-white/20">
            <h3 class="text-xl font-semibold text-white">AI-Powered Features</h3>
            <p class="mt-1 text-sm text-white/70">Configure how AI assists with your workflow</p>
          </div>

          <%!-- Beta Warning --%>
          <div class="bg-gradient-to-r from-yellow-400/20 to-orange-400/20 border border-yellow-400/30 rounded-lg m-4 p-6 backdrop-blur-sm">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-6 w-6 text-yellow-300"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z"
                  />
                </svg>
              </div>
              <div class="ml-4 flex-1">
                <h3 class="text-lg font-semibold text-yellow-100 mb-2">
                  🚀 Experimental AI Features
                </h3>
                <p class="text-yellow-200 text-sm leading-relaxed">
                  These are cutting-edge AI features still in beta. They're designed to enhance your experience but are experimental.
                  Your feedback helps us improve these features!
                </p>
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
                <div class="flex items-start p-4 rounded-lg border-2 border-white/20 hover:border-white/40 transition-colors bg-white/5">
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
                      🧠 Thought Extraction & Smart Reminders
                    </label>
                    <p class="text-white/80 text-sm leading-relaxed mb-3">
                      Enable AI to analyze your thoughts and automatically generate intelligent reminders.
                      This feature helps you capture important insights and never miss follow-up actions.
                    </p>
                    <div class="bg-blue-500/20 border border-blue-400/30 rounded-lg p-3 backdrop-blur-sm">
                      <div class="flex items-start">
                        <svg
                          class="h-5 w-5 text-blue-300 mt-0.5 mr-2"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        <div class="text-xs text-blue-200">
                          <strong>How it works:</strong>
                          Your thoughts are securely processed by AI to identify actionable items,
                          deadlines, and important concepts that become smart reminders.
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <:actions>
                <div class="text-sm text-white/60">
                  Changes are saved immediately and take effect for new thoughts.
                </div>
                <.button
                  phx-disable-with="Saving..."
                  class="bg-white/20 hover:bg-white/30 text-white font-medium py-2 px-6 rounded-lg shadow-sm transition-colors border border-white/30 backdrop-blur-sm"
                >
                  💾 Save Settings
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
