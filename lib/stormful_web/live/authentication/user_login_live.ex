defmodule StormfulWeb.UserLoginLive do
  use StormfulWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-12 mx-auto max-w-sm">
      <div class="flex flex-col items-center gap-4 text-lg text-center">
        <.cool_header big_name="Log in" />
        <p>
          Don't have an account? You can
          <.link navigate={~p"/users/register"} class="font-semibold text-yellow-400 hover:underline">
            join us
          </.link>
          here.
        </p>
      </div>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input
            class="text-white"
            field={@form[:remember_me]}
            type="checkbox"
            label="Keep me logged in"
          />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold text-white">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>

        <:actions>
          <.link
            href={~p"/users/rerequest_confirmation_mail"}
            class="w-full flex justify-center text-sm font-semibold text-white"
          >
            Receive confirmation instructions again
          </.link>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
