defmodule Stormful.TaskManagementFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.TaskManagement` context.
  """

  @doc """
  Generate a todo.
  """
  def todo_fixture(attrs \\ %{}) do
    {:ok, todo} =
      attrs
      |> Enum.into(%{
        completed_at: ~N[2024-09-12 20:51:00],
        description: "some description",
        loose_thought_link: 42,
        title: "some title"
      })
      |> Stormful.TaskManagement.create_todo()

    todo
  end
end
