defmodule Stormful.TaskManagementTest do
  use Stormful.DataCase

  alias Stormful.TaskManagement

  describe "todos" do
    alias Stormful.TaskManagement.Todo

    import Stormful.TaskManagementFixtures

    @invalid_attrs %{description: nil, title: nil, completed_at: nil, loose_thought_link: nil}

    test "list_todos/0 returns all todos" do
      todo = todo_fixture()
      assert TaskManagement.list_todos() == [todo]
    end

    test "get_todo!/1 returns the todo with given id" do
      todo = todo_fixture()
      assert TaskManagement.get_todo!(todo.id) == todo
    end

    test "create_todo/1 with valid data creates a todo" do
      valid_attrs = %{
        description: "some description",
        title: "some title",
        completed_at: ~N[2024-09-12 20:51:00],
        loose_thought_link: 42
      }

      assert {:ok, %Todo{} = todo} = TaskManagement.create_todo(valid_attrs)
      assert todo.description == "some description"
      assert todo.title == "some title"
      assert todo.completed_at == ~N[2024-09-12 20:51:00]
      assert todo.loose_thought_link == 42
    end

    test "create_todo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = TaskManagement.create_todo(@invalid_attrs)
    end

    test "update_todo/2 with valid data updates the todo" do
      todo = todo_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        completed_at: ~N[2024-09-13 20:51:00],
        loose_thought_link: 43
      }

      assert {:ok, %Todo{} = todo} = TaskManagement.update_todo(todo, update_attrs)
      assert todo.description == "some updated description"
      assert todo.title == "some updated title"
      assert todo.completed_at == ~N[2024-09-13 20:51:00]
      assert todo.loose_thought_link == 43
    end

    test "update_todo/2 with invalid data returns error changeset" do
      todo = todo_fixture()
      assert {:error, %Ecto.Changeset{}} = TaskManagement.update_todo(todo, @invalid_attrs)
      assert todo == TaskManagement.get_todo!(todo.id)
    end

    test "delete_todo/1 deletes the todo" do
      todo = todo_fixture()
      assert {:ok, %Todo{}} = TaskManagement.delete_todo(todo)
      assert_raise Ecto.NoResultsError, fn -> TaskManagement.get_todo!(todo.id) end
    end

    test "change_todo/1 returns a todo changeset" do
      todo = todo_fixture()
      assert %Ecto.Changeset{} = TaskManagement.change_todo(todo)
    end
  end
end
