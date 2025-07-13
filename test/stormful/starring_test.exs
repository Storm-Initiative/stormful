defmodule Stormful.StarringTest do
  use Stormful.DataCase

  alias Stormful.Starring

  describe "starred_sensicals" do
    alias Stormful.Starring.StarredSensical

    import Stormful.StarringFixtures

    @invalid_attrs %{}

    test "list_starred_sensicals/0 returns all starred_sensicals" do
      starred_sensical = starred_sensical_fixture()
      assert Starring.list_starred_sensicals() == [starred_sensical]
    end

    test "get_starred_sensical!/1 returns the starred_sensical with given id" do
      starred_sensical = starred_sensical_fixture()
      assert Starring.get_starred_sensical!(starred_sensical.id) == starred_sensical
    end

    test "create_starred_sensical/1 with valid data creates a starred_sensical" do
      valid_attrs = %{}

      assert {:ok, %StarredSensical{} = starred_sensical} =
               Starring.create_starred_sensical(valid_attrs)
    end

    test "create_starred_sensical/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Starring.create_starred_sensical(@invalid_attrs)
    end

    test "update_starred_sensical/2 with valid data updates the starred_sensical" do
      starred_sensical = starred_sensical_fixture()
      update_attrs = %{}

      assert {:ok, %StarredSensical{} = starred_sensical} =
               Starring.update_starred_sensical(starred_sensical, update_attrs)
    end

    test "update_starred_sensical/2 with invalid data returns error changeset" do
      starred_sensical = starred_sensical_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Starring.update_starred_sensical(starred_sensical, @invalid_attrs)

      assert starred_sensical == Starring.get_starred_sensical!(starred_sensical.id)
    end

    test "delete_starred_sensical/1 deletes the starred_sensical" do
      starred_sensical = starred_sensical_fixture()
      assert {:ok, %StarredSensical{}} = Starring.delete_starred_sensical(starred_sensical)

      assert_raise Ecto.NoResultsError, fn ->
        Starring.get_starred_sensical!(starred_sensical.id)
      end
    end

    test "change_starred_sensical/1 returns a starred_sensical changeset" do
      starred_sensical = starred_sensical_fixture()
      assert %Ecto.Changeset{} = Starring.change_starred_sensical(starred_sensical)
    end
  end
end
