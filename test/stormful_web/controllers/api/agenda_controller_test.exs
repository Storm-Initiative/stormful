defmodule StormfulWeb.Api.AgendaControllerTest do
  use StormfulWeb.ConnCase, async: true

  import Stormful.AccountsFixtures
  alias Stormful.{Accounts, AgendaRelated}

  describe "GET /api/v1/agenda" do
    test "returns agenda for authenticated user who has agenda", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      {:ok, agenda} =
        AgendaRelated.create_agenda(%{
          name: "My Personal Agenda",
          user_id: user.id
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda")

      assert json_response(conn, 200) == %{
               "id" => agenda.id,
               "name" => "My Personal Agenda",
               "user_id" => user.id,
               "inserted_at" => DateTime.to_iso8601(agenda.inserted_at),
               "updated_at" => DateTime.to_iso8601(agenda.updated_at)
             }
    end

    test "returns empty response for authenticated user who has no agenda", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda")

      assert json_response(conn, 200) == %{}
    end

    test "returns 401 for unauthenticated user", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/agenda")

      assert response(conn, 401) == "No access for you"
    end

    test "returns 401 for invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token")
        |> get(~p"/api/v1/agenda")

      assert response(conn, 401) == "No access for you"
    end
  end

  describe "GET /api/v1/agenda/events" do
    test "returns events for authenticated user who has agenda and events", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      {:ok, agenda} =
        AgendaRelated.create_agenda(%{
          name: "My Personal Agenda",
          user_id: user.id
        })

      event_date1 = ~U[2024-01-20 14:00:00Z]
      event_date2 = ~U[2024-01-21 10:00:00Z]

      {:ok, event1} =
        AgendaRelated.create_agenda_event(%{
          the_event: "Team meeting",
          event_date: event_date1,
          agenda_id: agenda.id,
          user_id: user.id
        })

      {:ok, event2} =
        AgendaRelated.create_agenda_event(%{
          the_event: "Project review",
          event_date: event_date2,
          agenda_id: agenda.id,
          user_id: user.id
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      response = json_response(conn, 200)

      assert length(response) == 2

      # Events should be ordered by event_date ascending
      assert Enum.at(response, 0) == %{
               "id" => event1.id,
               "the_event" => "Team meeting",
               "event_date" => DateTime.to_iso8601(event_date1),
               "agenda_id" => agenda.id,
               "user_id" => user.id,
               "inserted_at" => DateTime.to_iso8601(event1.inserted_at),
               "updated_at" => DateTime.to_iso8601(event1.updated_at)
             }

      assert Enum.at(response, 1) == %{
               "id" => event2.id,
               "the_event" => "Project review",
               "event_date" => DateTime.to_iso8601(event_date2),
               "agenda_id" => agenda.id,
               "user_id" => user.id,
               "inserted_at" => DateTime.to_iso8601(event2.inserted_at),
               "updated_at" => DateTime.to_iso8601(event2.updated_at)
             }
    end

    test "returns empty array for authenticated user who has no agenda", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      assert json_response(conn, 200) == []
    end

    test "returns empty array for authenticated user who has agenda but no events", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      {:ok, _agenda} =
        AgendaRelated.create_agenda(%{
          name: "My Personal Agenda",
          user_id: user.id
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      assert json_response(conn, 200) == []
    end

    test "returns 401 for unauthenticated user", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/agenda/events")

      assert response(conn, 401) == "No access for you"
    end

    test "returns 401 for invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token")
        |> get(~p"/api/v1/agenda/events")

      assert response(conn, 401) == "No access for you"
    end
  end
end
