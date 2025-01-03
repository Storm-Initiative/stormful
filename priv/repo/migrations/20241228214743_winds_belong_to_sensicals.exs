defmodule Stormful.Repo.Migrations.WindsBelongToSensicals do
  use Ecto.Migration

  def change do
    alter table(:winds) do
      add :sensical_id, references(:sensicals, on_delete: :delete_all)
    end

    create index(:winds, [:sensical_id])
  end
end
