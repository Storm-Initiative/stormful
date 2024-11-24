defmodule Stormful.SensicalityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.Sensicality` context.
  """

  @doc """
  Generate a sensical.
  """
  def sensical_fixture(attrs \\ %{}) do
    {:ok, sensical} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> Stormful.Sensicality.create_sensical()

    sensical
  end
end
