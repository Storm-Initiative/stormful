defmodule Stormful.BoardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.Boards` context.
  """

  @doc """
  Generate a board.
  """
  def board_fixture(attrs \\ %{}) do
    {:ok, board} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> Stormful.Boards.create_board()

    board
  end
end
