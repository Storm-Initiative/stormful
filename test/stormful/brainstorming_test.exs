defmodule Stormful.BrainstormingTest do
  use Stormful.DataCase

  alias Stormful.Brainstorming

  describe "thoughts" do
    alias Stormful.Brainstorming.Thought

    import Stormful.BrainstormingFixtures

    @invalid_attrs %{words: nil}

    test "list_thoughts/0 returns all thoughts" do
      thought = thought_fixture()
      assert Brainstorming.list_thoughts() == [thought]
    end

    test "get_thought!/1 returns the thought with given id" do
      thought = thought_fixture()
      assert Brainstorming.get_thought!(thought.id) == thought
    end

    test "create_thought/1 with valid data creates a thought" do
      valid_attrs = %{words: "some words"}

      assert {:ok, %Thought{} = thought} = Brainstorming.create_thought(valid_attrs)
      assert thought.words == "some words"
    end

    test "create_thought/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Brainstorming.create_thought(@invalid_attrs)
    end

    test "update_thought/2 with valid data updates the thought" do
      thought = thought_fixture()
      update_attrs = %{words: "some updated words"}

      assert {:ok, %Thought{} = thought} = Brainstorming.update_thought(thought, update_attrs)
      assert thought.words == "some updated words"
    end

    test "update_thought/2 with invalid data returns error changeset" do
      thought = thought_fixture()
      assert {:error, %Ecto.Changeset{}} = Brainstorming.update_thought(thought, @invalid_attrs)
      assert thought == Brainstorming.get_thought!(thought.id)
    end

    test "delete_thought/1 deletes the thought" do
      thought = thought_fixture()
      assert {:ok, %Thought{}} = Brainstorming.delete_thought(thought)
      assert_raise Ecto.NoResultsError, fn -> Brainstorming.get_thought!(thought.id) end
    end

    test "change_thought/1 returns a thought changeset" do
      thought = thought_fixture()
      assert %Ecto.Changeset{} = Brainstorming.change_thought(thought)
    end
  end
end
