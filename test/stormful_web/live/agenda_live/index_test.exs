defmodule StormfulWeb.AgendaLive.IndexTest do
  use StormfulWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Stormful.AccountsFixtures

  alias Stormful.AgendaRelated

  describe "fresh start" do
    test "archives current events and clears agenda list", %{conn: conn} do
      user = user_fixture()

      {:ok, agenda} =
        AgendaRelated.create_agenda(%{
          name: "Live Agenda",
          user_id: user.id
        })

      {:ok, event} =
        AgendaRelated.create_agenda_event(user.id, %{
          "the_event" => "Current event",
          "event_date" => DateTime.utc_now() |> DateTime.truncate(:second),
          "agenda_id" => agenda.id
        })

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/agenda")

      assert html =~ "Current event"
      assert html =~ "fuck this"

      lv
      |> element("button", "fuck this")
      |> render_click()

      refute render(lv) =~ "Current event"

      archived_event = AgendaRelated.get_agenda_event!(user.id, event.id)
      assert archived_event.archived_at != nil
    end
  end
end
