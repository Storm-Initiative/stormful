defmodule StormfulWeb.Authentication.UserAwaitingConfirmation do
  use StormfulWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4 text-lg text-center">
      <.cool_header big_name="Welcome to Stormful" />
      <p class="flex gap-2">
        Looks like you've just created an account.
      </p>
      <p>
        We've sent you an email with confirmation instructions. Please follow it and confirm your account and we'll get you right on track!
      </p>

      <div class="flex items-center gap-3">
        <.link
          href={~p"/users/log_out"}
          method="delete"
          class="group relative overflow-hidden rounded-lg px-3 py-1.5 text-sm font-semibold text-white/90
                       bg-black/20 hover:bg-black/40 border border-white/10 hover:border-white/20
                       transition-all duration-300 ease-out hover:-translate-y-0.5 hover:shadow-[0_0_15px_rgba(234,179,8,0.2)]
                       flex items-center gap-2 text-lg"
        >
          <.icon
            name="hero-arrow-right-on-rectangle"
            class="w-6 h-6 text-yellow-400 group-hover:text-blue-400 transition-colors duration-300"
          /> Log out
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    if current_user && current_user.confirmed_at do
      {:ok,
       socket
       |> redirect(to: ~p"/")
       |> put_flash(:info, "Confirmation was successful, welcome again!"),
       layout: {StormfulWeb.Layouts, :awaiting_confirmation}}
    else
      {:ok, socket, layout: {StormfulWeb.Layouts, :awaiting_confirmation}}
    end
  end
end
