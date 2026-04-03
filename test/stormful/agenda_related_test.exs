defmodule Stormful.AgendaRelatedTest do
  use Stormful.DataCase, async: true

  import Stormful.AccountsFixtures

  alias Stormful.AgendaRelated

  describe "archive_all_agenda_events/2" do
    test "archives active events and excludes them from list_agenda_events/2" do
      user = user_fixture()

      {:ok, agenda} =
        AgendaRelated.create_agenda(%{
          name: "Archive Test Agenda",
          user_id: user.id
        })

      event_date = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, event} =
        AgendaRelated.create_agenda_event(user.id, %{
          "the_event" => "A thing",
          "event_date" => event_date,
          "agenda_id" => agenda.id
        })

      assert [listed_event] = AgendaRelated.list_agenda_events(user.id, agenda.id)
      assert listed_event.id == event.id

      assert {1, _} = AgendaRelated.archive_all_agenda_events(user.id, agenda.id)

      assert [] == AgendaRelated.list_agenda_events(user.id, agenda.id)

      archived_event = AgendaRelated.get_agenda_event!(user.id, event.id)
      assert archived_event.archived_at != nil
    end
  end
end
