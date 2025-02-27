defmodule Stormful.AttentionFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.Attention` context.
  """

  @doc """
  Generate a headsup.
  """
  def headsup_fixture(attrs \\ %{}) do
    {:ok, headsup} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> Stormful.Attention.create_headsup()

    headsup
  end
end
