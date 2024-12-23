defmodule StormfulWeb.Immersive.ImmerseSensicalLive do
  alias Stormful.Planning

  alias Stormful.Sensicality
  # alias Stormful.Sensicality.Sensical

  use StormfulWeb, :live_view
  use StormfulWeb.BaseUtil.Controlful

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user
    current_user_id = current_user.id

    _sensical = Sensicality.get_sensical!(current_user_id, params["sensical_id"])
    _plan = Planning.get_plan_from_sensical!(current_user_id, params["plan_id"])

    {:ok,
     socket
     |> assign_controlful()}
  end

  use StormfulWeb.BaseUtil.KeyboardSupport
end
