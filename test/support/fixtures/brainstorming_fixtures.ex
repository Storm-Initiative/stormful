defmodule Stormful.BrainstormingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.Brainstorming` context.
  """

  @doc """
  Generate a thought.
  """
  def thought_fixture(attrs \\ %{}) do
    {:ok, thought} =
      attrs
      |> Enum.into(%{
        words: "some words"
      })
      |> Stormful.Brainstorming.create_thought()

    thought
  end
end
