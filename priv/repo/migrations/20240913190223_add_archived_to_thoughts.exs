defmodule Stormful.Repo.Migrations.AddArchivedToThoughts do
  use Ecto.Migration

  def change do
    alter table(:thoughts) do
      add :archived, :boolean, default: false
    end
  end
end
