defmodule Stormful.SensicalityTest do
  use Stormful.DataCase

  alias Stormful.Sensicality

  describe "sensicals" do
    alias Stormful.Sensicality.Sensical

    import Stormful.SensicalityFixtures

    @invalid_attrs %{title: nil}

    test "list_sensicals/0 returns all sensicals" do
      sensical = sensical_fixture()
      assert Sensicality.list_sensicals() == [sensical]
    end

    test "get_sensical!/1 returns the sensical with given id" do
      sensical = sensical_fixture()
      assert Sensicality.get_sensical!(sensical.id) == sensical
    end

    test "create_sensical/1 with valid data creates a sensical" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Sensical{} = sensical} = Sensicality.create_sensical(valid_attrs)
      assert sensical.title == "some title"
    end

    test "create_sensical/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sensicality.create_sensical(@invalid_attrs)
    end

    test "update_sensical/2 with valid data updates the sensical" do
      sensical = sensical_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Sensical{} = sensical} = Sensicality.update_sensical(sensical, update_attrs)
      assert sensical.title == "some updated title"
    end

    test "update_sensical/2 with invalid data returns error changeset" do
      sensical = sensical_fixture()
      assert {:error, %Ecto.Changeset{}} = Sensicality.update_sensical(sensical, @invalid_attrs)
      assert sensical == Sensicality.get_sensical!(sensical.id)
    end

    test "delete_sensical/1 deletes the sensical" do
      sensical = sensical_fixture()
      assert {:ok, %Sensical{}} = Sensicality.delete_sensical(sensical)
      assert_raise Ecto.NoResultsError, fn -> Sensicality.get_sensical!(sensical.id) end
    end

    test "change_sensical/1 returns a sensical changeset" do
      sensical = sensical_fixture()
      assert %Ecto.Changeset{} = Sensicality.change_sensical(sensical)
    end
  end
end
