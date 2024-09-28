defmodule Stormful.Repo.Migrations.CreateThoughts do
  use Ecto.Migration

  def change do
    create table(:thoughts) do
      add :words, :text

      timestamps(type: :utc_datetime)
    end
  end
end
