defmodule Stormful.Repo.Migrations.ProfileSystemInitialization do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :thought_extraction, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:profiles, [:user_id])
  end
end
