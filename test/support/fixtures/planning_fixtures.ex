defmodule Stormful.PlanningFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.Planning` context.
  """

  @doc """
  Generate a plan.
  """
  def plan_fixture(attrs \\ %{}) do
    {:ok, plan} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> Stormful.Planning.create_plan()

    plan
  end
end
