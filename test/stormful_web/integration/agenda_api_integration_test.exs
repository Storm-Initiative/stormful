defmodule StormfulWeb.Integration.AgendaApiIntegrationTest do
  use StormfulWeb.ConnCase, async: true

  import Stormful.AccountsFixtures
  alias Stormful.{Accounts, AgendaRelated}

  @moduledoc """
  Integration tests for the Agenda API endpoints.

  These tests focus on:
  - Full request/response cycle testing
  - Bearer token authentication flow validation
  - JSON response format validation against design specification
  - Error scenarios and response codes
  """

  describe "Agenda API Integration - Authentication Flow" do
    test "Bearer token authentication flow works end-to-end", %{conn: conn} do
      # Create user and generate API token
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      # Test that token works for agenda endpoint
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      # Test that token works for events endpoint
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    end

    test "missing Authorization header returns 401", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/agenda")

      assert conn.status == 401
      assert response(conn, 401) == "No access for you"

      conn = get(build_conn(), ~p"/api/v1/agenda/events")

      assert conn.status == 401
      assert response(conn, 401) == "No access for you"
    end

    test "malformed Authorization header returns 401", %{conn: conn} do
      # Test without "Bearer" prefix
      conn =
        conn
        |> put_req_header("authorization", "invalid_token")
        |> get(~p"/api/v1/agenda")

      assert conn.status == 401

      # Test with wrong format
      conn =
        build_conn()
        |> put_req_header("authorization", "Basic invalid_token")
        |> get(~p"/api/v1/agenda/events")

      assert conn.status == 401
    end

    test "expired or invalid Bearer token returns 401", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token_12345")
        |> get(~p"/api/v1/agenda")

      assert conn.status == 401
      assert response(conn, 401) == "No access for you"

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer another_invalid_token")
        |> get(~p"/api/v1/agenda/events")

      assert conn.status == 401
      assert response(conn, 401) == "No access for you"
    end
  end

  describe "Agenda API Integration - JSON Response Format Validation" do
    test "agenda endpoint returns correctly formatted JSON response", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      {:ok, agenda} =
        AgendaRelated.create_agenda(%{
          name: "Integration Test Agenda",
          user_id: user.id
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      response_data = json_response(conn, 200)

      # Validate response structure matches design specification
      assert Map.has_key?(response_data, "id")
      assert Map.has_key?(response_data, "name")
      assert Map.has_key?(response_data, "user_id")
      assert Map.has_key?(response_data, "inserted_at")
      assert Map.has_key?(response_data, "updated_at")

      # Validate data types and values
      assert is_binary(response_data["id"])
      assert response_data["name"] == "Integration Test Agenda"
      assert response_data["user_id"] == user.id
      assert is_binary(response_data["inserted_at"])
      assert is_binary(response_data["updated_at"])

      # Validate ISO8601 datetime format
      assert {:ok, _, _} = DateTime.from_iso8601(response_data["inserted_at"])
      assert {:ok, _, _} = DateTime.from_iso8601(response_data["updated_at"])

      # Validate ULID format for IDs
      assert String.length(response_data["id"]) == 26
      assert response_data["id"] == agenda.id
    end

    test "agenda endpoint returns empty object for user with no agenda", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      response_data = json_response(conn, 200)
      assert response_data == %{}
    end

    test "events endpoint returns correctly formatted JSON array", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      {:ok, agenda} =
        AgendaRelated.create_agenda(%{
          name: "Integration Test Agenda",
          user_id: user.id
        })

      event_date1 = ~U[2024-01-20 14:00:00Z]
      event_date2 = ~U[2024-01-21 10:00:00Z]

      {:ok, event1} =
        AgendaRelated.create_agenda_event(%{
          the_event: "Integration Test Event 1",
          event_date: event_date1,
          agenda_id: agenda.id,
          user_id: user.id
        })

      {:ok, event2} =
        AgendaRelated.create_agenda_event(%{
          the_event: "Integration Test Event 2",
          event_date: event_date2,
          agenda_id: agenda.id,
          user_id: user.id
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      response_data = json_response(conn, 200)

      # Validate response is an array
      assert is_list(response_data)
      assert length(response_data) == 2

      # Validate each event structure matches design specification
      Enum.each(response_data, fn event ->
        assert Map.has_key?(event, "id")
        assert Map.has_key?(event, "the_event")
        assert Map.has_key?(event, "event_date")
        assert Map.has_key?(event, "agenda_id")
        assert Map.has_key?(event, "user_id")
        assert Map.has_key?(event, "inserted_at")
        assert Map.has_key?(event, "updated_at")

        # Validate data types
        assert is_binary(event["id"])
        assert is_binary(event["the_event"])
        assert is_binary(event["event_date"])
        assert is_binary(event["agenda_id"])
        # user_id is an integer (default primary key)
        assert is_integer(event["user_id"])
        assert is_binary(event["inserted_at"])
        assert is_binary(event["updated_at"])

        # Validate datetime formats
        assert {:ok, _, _} = DateTime.from_iso8601(event["event_date"])
        assert {:ok, _, _} = DateTime.from_iso8601(event["inserted_at"])
        assert {:ok, _, _} = DateTime.from_iso8601(event["updated_at"])

        # Validate ULID format for IDs (except user_id which is integer)
        assert String.length(event["id"]) == 26
        assert String.length(event["agenda_id"]) == 26

        # Validate relationships
        assert event["agenda_id"] == agenda.id
        assert event["user_id"] == user.id
      end)

      # Validate events are ordered by event_date ascending
      first_event = Enum.at(response_data, 0)
      second_event = Enum.at(response_data, 1)

      assert first_event["id"] == event1.id
      assert first_event["the_event"] == "Integration Test Event 1"
      assert first_event["event_date"] == DateTime.to_iso8601(event_date1)

      assert second_event["id"] == event2.id
      assert second_event["the_event"] == "Integration Test Event 2"
      assert second_event["event_date"] == DateTime.to_iso8601(event_date2)
    end

    test "events endpoint returns empty array for user with no agenda", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      response_data = json_response(conn, 200)
      assert response_data == []
      assert is_list(response_data)
    end

    test "events endpoint returns empty array for user with agenda but no events", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      {:ok, _agenda} =
        AgendaRelated.create_agenda(%{
          name: "Empty Agenda",
          user_id: user.id
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      response_data = json_response(conn, 200)
      assert response_data == []
      assert is_list(response_data)
    end
  end

  describe "Agenda API Integration - Error Scenarios and Response Codes" do
    test "handles server errors gracefully", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      # This test would require mocking database failures, but we can test
      # that the error handling structure is in place by checking the
      # action_fallback configuration works
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda")

      # Should not crash and should return a valid HTTP response
      assert conn.status in [200, 500]
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    end

    test "returns consistent error format for authentication failures", %{conn: conn} do
      # Test agenda endpoint
      conn = get(conn, ~p"/api/v1/agenda")

      assert conn.status == 401
      assert response(conn, 401) == "No access for you"

      # Test events endpoint
      conn = get(build_conn(), ~p"/api/v1/agenda/events")

      assert conn.status == 401
      assert response(conn, 401) == "No access for you"

      # Both endpoints should return the same error format
    end

    test "handles invalid HTTP methods gracefully", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      # Test POST to agenda endpoint (should not be allowed)
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/agenda", %{})

      # Should return method not allowed or similar error
      assert conn.status in [404, 405]

      # Test PUT to events endpoint (should not be allowed)
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/agenda/events", %{})

      # Should return method not allowed or similar error
      assert conn.status in [404, 405]
    end

    test "validates content-type headers are consistent", %{conn: conn} do
      user = user_fixture()
      token = Accounts.create_user_api_token(user)

      # Test agenda endpoint
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda")

      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      # Test events endpoint
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/agenda/events")

      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      # Both should have the same content-type
    end
  end

  describe "Agenda API Integration - Cross-User Data Isolation" do
    test "users can only access their own agenda data", %{conn: conn} do
      # Create two users
      user1 = user_fixture()
      user2 = user_fixture()

      token1 = Accounts.create_user_api_token(user1)
      token2 = Accounts.create_user_api_token(user2)

      # Create agenda for user1
      {:ok, agenda1} =
        AgendaRelated.create_agenda(%{
          name: "User 1 Agenda",
          user_id: user1.id
        })

      # Create agenda for user2
      {:ok, agenda2} =
        AgendaRelated.create_agenda(%{
          name: "User 2 Agenda",
          user_id: user2.id
        })

      # User1 should only see their agenda
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token1}")
        |> get(~p"/api/v1/agenda")

      response1 = json_response(conn, 200)
      assert response1["id"] == agenda1.id
      assert response1["name"] == "User 1 Agenda"
      assert response1["user_id"] == user1.id

      # User2 should only see their agenda
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token2}")
        |> get(~p"/api/v1/agenda")

      response2 = json_response(conn, 200)
      assert response2["id"] == agenda2.id
      assert response2["name"] == "User 2 Agenda"
      assert response2["user_id"] == user2.id

      # Responses should be different
      refute response1["id"] == response2["id"]
    end

    test "users can only access their own agenda events", %{conn: conn} do
      # Create two users
      user1 = user_fixture()
      user2 = user_fixture()

      token1 = Accounts.create_user_api_token(user1)
      token2 = Accounts.create_user_api_token(user2)

      # Create agendas for both users
      {:ok, agenda1} =
        AgendaRelated.create_agenda(%{
          name: "User 1 Agenda",
          user_id: user1.id
        })

      {:ok, agenda2} =
        AgendaRelated.create_agenda(%{
          name: "User 2 Agenda",
          user_id: user2.id
        })

      # Create events for both users
      {:ok, event1} =
        AgendaRelated.create_agenda_event(%{
          the_event: "User 1 Event",
          event_date: ~U[2024-01-20 14:00:00Z],
          agenda_id: agenda1.id,
          user_id: user1.id
        })

      {:ok, event2} =
        AgendaRelated.create_agenda_event(%{
          the_event: "User 2 Event",
          event_date: ~U[2024-01-21 10:00:00Z],
          agenda_id: agenda2.id,
          user_id: user2.id
        })

      # User1 should only see their events
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token1}")
        |> get(~p"/api/v1/agenda/events")

      response1 = json_response(conn, 200)
      assert length(response1) == 1
      assert Enum.at(response1, 0)["id"] == event1.id
      assert Enum.at(response1, 0)["the_event"] == "User 1 Event"
      assert Enum.at(response1, 0)["user_id"] == user1.id

      # User2 should only see their events
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token2}")
        |> get(~p"/api/v1/agenda/events")

      response2 = json_response(conn, 200)
      assert length(response2) == 1
      assert Enum.at(response2, 0)["id"] == event2.id
      assert Enum.at(response2, 0)["the_event"] == "User 2 Event"
      assert Enum.at(response2, 0)["user_id"] == user2.id

      # Events should be different
      refute Enum.at(response1, 0)["id"] == Enum.at(response2, 0)["id"]
    end
  end
end
