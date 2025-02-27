defmodule Stormful.AttentionTest do
  use Stormful.DataCase

  alias Stormful.Attention

  describe "headsups" do
    alias Stormful.Attention.Headsup

    import Stormful.AttentionFixtures

    @invalid_attrs %{description: nil, title: nil}

    test "list_headsups/0 returns all headsups" do
      headsup = headsup_fixture()
      assert Attention.list_headsups() == [headsup]
    end

    test "get_headsup!/1 returns the headsup with given id" do
      headsup = headsup_fixture()
      assert Attention.get_headsup!(headsup.id) == headsup
    end

    test "create_headsup/1 with valid data creates a headsup" do
      valid_attrs = %{description: "some description", title: "some title"}

      assert {:ok, %Headsup{} = headsup} = Attention.create_headsup(valid_attrs)
      assert headsup.description == "some description"
      assert headsup.title == "some title"
    end

    test "create_headsup/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Attention.create_headsup(@invalid_attrs)
    end

    test "update_headsup/2 with valid data updates the headsup" do
      headsup = headsup_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title"}

      assert {:ok, %Headsup{} = headsup} = Attention.update_headsup(headsup, update_attrs)
      assert headsup.description == "some updated description"
      assert headsup.title == "some updated title"
    end

    test "update_headsup/2 with invalid data returns error changeset" do
      headsup = headsup_fixture()
      assert {:error, %Ecto.Changeset{}} = Attention.update_headsup(headsup, @invalid_attrs)
      assert headsup == Attention.get_headsup!(headsup.id)
    end

    test "delete_headsup/1 deletes the headsup" do
      headsup = headsup_fixture()
      assert {:ok, %Headsup{}} = Attention.delete_headsup(headsup)
      assert_raise Ecto.NoResultsError, fn -> Attention.get_headsup!(headsup.id) end
    end

    test "change_headsup/1 returns a headsup changeset" do
      headsup = headsup_fixture()
      assert %Ecto.Changeset{} = Attention.change_headsup(headsup)
    end
  end
end
