defmodule StormfulWeb.Api.FallbackController do
  use StormfulWeb, :controller

  def call(conn, {:error, reason}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: reason})
  end
end
