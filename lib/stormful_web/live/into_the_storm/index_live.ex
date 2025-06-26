defmodule StormfulWeb.IntoTheStorm.IndexLive do
  alias Stormful.Starring
  alias Stormful.Sensicality
  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

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
        <.link navigate={~p"/sensicality/begin"} class="group relative">
          <button class="relative overflow-hidden rounded-xl px-8 py-4 text-xl font-bold text-white/90
                         bg-gradient-to-r from-yellow-600/80 to-orange-600/80 
                         hover:from-yellow-500/90 hover:to-orange-500/90
                         border border-yellow-400/30 hover:border-yellow-300/50
                         transition-all duration-300 ease-out hover:-translate-y-1 
                         hover:shadow-[0_10px_30px_rgba(251,191,36,0.3)]">
            <!-- Subtle shine effect -->
            <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent 
                        -translate-x-full group-hover:translate-x-full transition-transform duration-700">
            </div>
            
            <div class="relative flex items-center gap-3">
              <.icon name="hero-bolt" class="w-6 h-6 text-yellow-200 group-hover:text-white transition-colors duration-300" />
              <span class="group-hover:text-white transition-colors duration-300">
                We strike, once more!
              </span>
              <.icon name="hero-arrow-right" class="w-5 h-5 text-yellow-200 group-hover:translate-x-1 group-hover:text-white transition-all duration-300" />
            </div>
          </button>
        </.link>
      </div>

      <!-- Starred Sensicals Section -->
      <div class="space-y-6">
        <div>
          <h2 class="text-2xl font-bold mb-4">
            <.cool_header little_name="Favorites" big_name="The Starred Ones" />
          </h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.link
              :for={starred_sensicality <- @starred_sensicalities}
              navigate={~p"/sensicality/#{starred_sensicality.sensical.id}"}
              class="group relative overflow-hidden rounded-xl px-6 py-4 
                     bg-gradient-to-r from-yellow-600/20 to-orange-600/20
                     hover:from-yellow-500/30 hover:to-orange-500/30
                     border border-yellow-400/20 hover:border-yellow-300/40
                     transition-all duration-300 ease-out hover:-translate-y-1
                     hover:shadow-[0_8px_25px_rgba(251,191,36,0.2)]"
            >
              <!-- Subtle shine effect -->
              <div class="absolute inset-0 bg-gradient-to-r from-transparent via-yellow-300/10 to-transparent 
                          -translate-x-full group-hover:translate-x-full transition-transform duration-700">
              </div>
              
              <div class="relative flex items-center gap-3">
                <.icon name="hero-star" class="w-5 h-5 text-yellow-300 group-hover:text-yellow-200 transition-colors duration-300" />
                <h3 class="text-lg font-semibold text-white/90 group-hover:text-white transition-colors duration-300">
                  {starred_sensicality.sensical.title}
                </h3>
              </div>
            </.link>
          </div>
        </div>

        <!-- Regular Sensicals Section -->
        <div>
          <h2 class="text-2xl font-bold mb-4">
            <.cool_header little_name="All projects" big_name="The Collection" />
          </h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <.link
              :for={sensicality <- @sensicalities}
              navigate={~p"/sensicality/#{sensicality}"}
              class="group relative overflow-hidden rounded-xl px-6 py-4
                     bg-gradient-to-r from-indigo-600/20 to-blue-600/20
                     hover:from-indigo-500/30 hover:to-blue-500/30
                     border border-indigo-400/20 hover:border-indigo-300/40
                     transition-all duration-300 ease-out hover:-translate-y-1
                     hover:shadow-[0_8px_25px_rgba(99,102,241,0.2)]"
            >
              <!-- Subtle shine effect -->
              <div class="absolute inset-0 bg-gradient-to-r from-transparent via-blue-300/10 to-transparent 
                          -translate-x-full group-hover:translate-x-full transition-transform duration-700">
              </div>
              
              <div class="relative flex items-center gap-3">
                <.icon name="hero-bolt" class="w-5 h-5 text-blue-300 group-hover:text-blue-200 transition-colors duration-300" />
                <h3 class="text-lg font-semibold text-white/90 group-hover:text-white transition-colors duration-300">
                  {sensicality.title}
                </h3>
              </div>
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
