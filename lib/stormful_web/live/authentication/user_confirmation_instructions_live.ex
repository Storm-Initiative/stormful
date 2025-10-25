defmodule StormfulWeb.UserConfirmationInstructionsLive do
  use StormfulWeb, :live_view

  alias Stormful.Accounts

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-12 mx-auto max-w-sm">
      <div class="flex flex-col items-center gap-4 text-lg text-center">
        <.cool_header big_name="Resend confirmation" />
        <p>
          You didn't receive the e-mail, or it expired, or whatever else? No problem, we'll send a new confirmation link to your inbox
        </p>
      </div>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Resend confirmation instructions
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={~p"/users/register"}>Register</.link>
        | <.link href={~p"/users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
