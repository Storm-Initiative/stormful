defmodule Stormful.FlowingThoughtsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.FlowingThoughts` context.
  """

  @doc """
  Generate a wind.
  """
  def wind_fixture(attrs \\ %{}) do
    {:ok, wind} =
      attrs
      |> Enum.into(%{
        long_words: "some long_words",
        words: "some words"
      })
      |> Stormful.FlowingThoughts.create_wind()

    wind
  end
end
