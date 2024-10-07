defmodule StormfulWeb.PageController do
  use StormfulWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/thoughts")
    else
      render(conn, :home, layout: false)
    end
  end
end
