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
        <.button class="text-2xl font-semibold bg-black flex items-center w-full py-6">
          Another!<.icon name="hero-arrow-right" class="w-5 h-5 ml-2" />
        </.button>
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
            class="bg-black px-8 py-4 rounded-xl border-2"
            navigate={~p"/sensicality/#{sensicality}"}
          >
            <h4 class="text-xl font-semibold">
              <%= sensicality.title %>
            </h4>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
