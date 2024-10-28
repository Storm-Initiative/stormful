defmodule Stormful.ArchivesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stormful.Archives` context.
  """

  @doc """
  Generate a archive.
  """
  def archive_fixture(attrs \\ %{}) do
    {:ok, archive} =
      attrs
      |> Enum.into(%{
        color_code: "some color_code",
        context: "some context"
      })
      |> Stormful.Archives.create_archive()

    archive
  end
end
