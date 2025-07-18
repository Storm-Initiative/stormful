defmodule StormfulWeb.Api.AuthController do
  use StormfulWeb, :controller

  alias Stormful.Accounts
  alias Stormful.Accounts.User

  action_fallback StormfulWeb.Api.FallbackController

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %User{} = user ->
        token = Accounts.create_user_api_token(user)

        Phoenix.PubSub.broadcast(Stormful.PubSub, "user_api_tokens:#{user.id}", {:new_token})

        conn
        |> put_status(:ok)
        |> json(%{token: token})

      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def login(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid request"})
  end
end
