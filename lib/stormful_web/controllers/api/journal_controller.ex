defmodule StormfulWeb.Api.JournalController do
  use StormfulWeb, :controller

  alias Stormful.Journaling
  alias Stormful.FlowingThoughts

  action_fallback StormfulWeb.Api.FallbackController

  def create(conn, %{"words" => words}) do
    user = conn.assigns.current_user
    # Ensure the user has access to this journal
    journal = Journaling.get_journal_from_user_id!(user.id)

    with {:ok, _wind} <-
           FlowingThoughts.create_wind(user, %{
             user_id: user.id,
             journal_id: journal.id,
             words: words
           }) do
      send_resp(conn, :created, "")
    end
  end
end
