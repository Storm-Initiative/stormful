defmodule Stormful.StarringFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.Starring` context.
  """

  @doc """
  Generate a starred_sensical.
  """
  def starred_sensical_fixture(attrs \\ %{}) do
    {:ok, starred_sensical} =
      attrs
      |> Enum.into(%{})
      |> Stormful.Starring.create_starred_sensical()

    starred_sensical
  end
end
