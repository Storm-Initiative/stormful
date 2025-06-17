defmodule Stormful.Repo.Migrations.AddJournalToWinds do
  use Ecto.Migration

  def up do
    alter table(:winds) do
      add :journal_id, references(:journals, type: :binary_id, on_delete: :delete_all), null: true
    end

    create index(:winds, [:journal_id])

    # Drop the existing foreign key constraint and recreate it with null: true
    drop constraint(:winds, "winds_sensical_id_fkey")

    alter table(:winds) do
      modify :sensical_id, :integer, null: true
    end

    # Add the foreign key constraint back
    alter table(:winds) do
      modify :sensical_id, references(:sensicals, on_delete: :delete_all), null: true
    end
  end

  def down do
    alter table(:winds) do
      remove :journal_id
    end
  end
end
