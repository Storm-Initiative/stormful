defmodule StormfulWeb.IntoTheStorm.IndexLive do
  alias Stormful.Starring
  alias Stormful.Sensicality
  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful
  import StormfulWeb.SensicalCard
  import StormfulWeb.StormButton

  # Egemendir irmaga Katyusha, etkisi sarsilmaz uzere

  def mount(_params, _session, socket) do
    sensicalities = Sensicality.list_sensicals(socket.assigns.current_user.id)
    starred_sensicalities = Starring.list_starred_sensicals(socket.assigns.current_user.id)

    {:ok,
     socket
     |> assign(sensicalities: sensicalities)
     |> assign(starred_sensicalities: starred_sensicalities)
     |> assign_controlful()}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Header -->
      <div class="text-center">
        <h1 class="text-4xl font-bold mb-4">
          <.cool_header little_name="Ready to dive?" big_name="Into the Storm" />
        </h1>
        <p class="text-lg text-white/70 max-w-md mx-auto">
          Where your best ideas come to life. Let's create something amazing.
        </p>
      </div>

      <!-- Main CTA Button -->
      <div class="flex justify-center">
        <.storm_button 
          variant="cta" 
          navigate={~p"/sensicality/begin"} 
          icon="hero-bolt"
        >
          We strike, once more!
        </.storm_button>
      </div>

      <!-- Starred Sensicals Section -->
      <div class="space-y-6">
        <div>
          <h2 class="text-2xl font-bold mb-4">
            <.cool_header little_name="Favorites" big_name="The Starred Ones" />
          </h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.sensical_card
              :for={starred_sensicality <- @starred_sensicalities}
              title={starred_sensicality.sensical.title}
              href={~p"/sensicality/#{starred_sensicality.sensical.id}"}
              variant="starred"
            />
          </div>
        </div>

        <!-- Regular Sensicals Section -->
        <div>
          <h2 class="text-2xl font-bold mb-4">
            <.cool_header little_name="All projects" big_name="The Collection" />
          </h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <.sensical_card
              :for={sensicality <- @sensicalities}
              title={sensicality.title}
              href={~p"/sensicality/#{sensicality}"}
              variant="regular"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
