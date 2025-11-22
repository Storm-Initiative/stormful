defmodule StormfulWeb.PageController do
  alias Stormful.ProfileManagement
  use StormfulWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    current_user = conn.assigns[:current_user]

    if current_user do
      users_landing_destination =
        ProfileManagement.get_the_destination_for_the_user_to_land(current_user)

      redirect(conn, to: users_landing_destination)
    else
      render(conn, :home, layout: false)
    end
  end
end
