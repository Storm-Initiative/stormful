defmodule StormfulWeb.IntoTheStorm.IndexLive do
  alias Stormful.Sensicality
  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

  # Egemendir irmaga Katyusha, etkisi sarsilmaz uzere

  def mount(_params, _session, socket) do
    sensicalities = Sensicality.list_sensicals(socket.assigns.current_user.id)

    {:ok, socket |> assign(sensicalities: sensicalities) |> assign_controlful()}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold">
      <.cool_header little_name="Let's go" big_name="Into the Storm" />
    </h1>
    <div class="mt-12 flex">
      <.link navigate={~p"/sensicality/begin"} class="flex w-full">
        <button class="group relative w-full overflow-hidden rounded-lg border-2 border-white/80 bg-black px-3 py-6 text-2xl font-semibold transition-all duration-300 hover:-translate-y-0.5 hover:bg-zinc-800 hover:shadow-lg hover:shadow-blue-500/20 active:translate-y-0 active:scale-[0.98]">
          <div class="relative flex items-center justify-center gap-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 text-yellow-300 transition-colors duration-300 group-hover:text-blue-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>

            <span class="transition-all duration-300 group-hover:scale-[1.02] group-hover:text-white">
              We strike, once more!
            </span>

            <span class="hero-arrow-right ml-2 h-5 w-5 transform transition-all duration-300 group-hover:translate-x-1 group-hover:text-blue-400">
            </span>
          </div>
          <!-- The electric shine effect! -->
          <div class="absolute inset-0 -left-full bg-gradient-to-r from-transparent via-blue-500/10 to-transparent transition-transform duration-700 group-hover:translate-x-full">
          </div>
        </button>
      </.link>
    </div>

    <div class="mt-8">
      <h2 class="mb-4">
        <.cool_header little_name="Not forgotten(yet)" big_name="The old ones" />
      </h2>
      <div class="border-t-2">
        <div class="flex flex-wrap gap-4 mt-4">
          <.link
            :for={sensicality <- @sensicalities}
            navigate={~p"/sensicality/#{sensicality}"}
            class="group relative overflow-hidden bg-black px-8 py-4 rounded-xl border-2 border-zinc-800 transition-all duration-300 
    hover:border-white/80 
    hover:-translate-y-0.5 
    hover:shadow-lg 
    hover:shadow-yellow-500/20 
    active:translate-y-0 
    active:scale-[0.98]
    hover:bg-zinc-900"
          >
            <!-- Enhanced gradient hover effect -->
            <div class="absolute inset-0 bg-gradient-to-r from-yellow-900/0 via-blue-500/5 to-yellow-900/0 opacity-0 group-hover:opacity-100 transition-transform duration-700 group-hover:translate-x-full">
            </div>
            <!-- Lightning bolt icon with reversed color transition -->
            <div class="flex items-center gap-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 text-blue-400 transition-colors duration-300 group-hover:text-yellow-300"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
              <!-- Title with enhanced hover effect -->
              <h4 class="text-xl font-semibold relative transition-all duration-300 
      group-hover:text-white 
      group-hover:scale-[1.02]">
                {sensicality.title}
              </h4>
            </div>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
