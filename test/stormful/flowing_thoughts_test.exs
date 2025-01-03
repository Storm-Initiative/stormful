defmodule Stormful.FlowingThoughtsTest do
  use Stormful.DataCase

  alias Stormful.FlowingThoughts

  describe "winds" do
    alias Stormful.FlowingThoughts.Wind

    import Stormful.FlowingThoughtsFixtures

    @invalid_attrs %{words: nil, long_words: nil}

    test "list_winds/0 returns all winds" do
      wind = wind_fixture()
      assert FlowingThoughts.list_winds() == [wind]
    end

    test "get_wind!/1 returns the wind with given id" do
      wind = wind_fixture()
      assert FlowingThoughts.get_wind!(wind.id) == wind
    end

    test "create_wind/1 with valid data creates a wind" do
      valid_attrs = %{words: "some words", long_words: "some long_words"}

      assert {:ok, %Wind{} = wind} = FlowingThoughts.create_wind(valid_attrs)
      assert wind.words == "some words"
      assert wind.long_words == "some long_words"
    end

    test "create_wind/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FlowingThoughts.create_wind(@invalid_attrs)
    end

    test "update_wind/2 with valid data updates the wind" do
      wind = wind_fixture()
      update_attrs = %{words: "some updated words", long_words: "some updated long_words"}

      assert {:ok, %Wind{} = wind} = FlowingThoughts.update_wind(wind, update_attrs)
      assert wind.words == "some updated words"
      assert wind.long_words == "some updated long_words"
    end

    test "update_wind/2 with invalid data returns error changeset" do
      wind = wind_fixture()
      assert {:error, %Ecto.Changeset{}} = FlowingThoughts.update_wind(wind, @invalid_attrs)
      assert wind == FlowingThoughts.get_wind!(wind.id)
    end

    test "delete_wind/1 deletes the wind" do
      wind = wind_fixture()
      assert {:ok, %Wind{}} = FlowingThoughts.delete_wind(wind)
      assert_raise Ecto.NoResultsError, fn -> FlowingThoughts.get_wind!(wind.id) end
    end

    test "change_wind/1 returns a wind changeset" do
      wind = wind_fixture()
      assert %Ecto.Changeset{} = FlowingThoughts.change_wind(wind)
    end
  end
end
