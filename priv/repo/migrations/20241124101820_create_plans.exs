defmodule Stormful.Repo.Migrations.CreatePlans do
  use Ecto.Migration

  def change do
    create table(:plans) do
      add :title, :string
      add :sensical_id, references(:sensicals, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:plans, [:sensical_id])
  end
end
