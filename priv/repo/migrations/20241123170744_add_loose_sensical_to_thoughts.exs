defmodule Stormful.Repo.Migrations.AddLooseSensicalToThoughts do
  use Ecto.Migration

  def change do
    alter table(:thoughts) do
      add :sensical_id, references(:sensicals, on_delete: :nilify_all)
    end
  end
end
