defmodule StormfulWeb.WindController do
  alias Stormful.FlowingThoughts
  use StormfulWeb, :controller

  def singular_wind(conn, %{"wind_id" => wind_id}) do
    if conn.assigns[:current_user] do
      current_user = conn.assigns[:current_user]

      wind = FlowingThoughts.get_wind!(current_user.id, wind_id)
      words = wind.words

      render(conn, :singular_wind, words: words, layout: false)
    else
      redirect(conn, to: ~p"/into-the-storm")
    end
  end
end
