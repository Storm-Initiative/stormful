defmodule Stormful.Repo.Migrations.CreateStarredSensicals do
  use Ecto.Migration

  def change do
    create table(:starred_sensicals, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true

      add :sensical_id, references(:sensicals, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:starred_sensicals, [:user_id, :sensical_id])
  end
end
