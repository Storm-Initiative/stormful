defmodule Stormful.Repo.Migrations.CreateJournals do
  use Ecto.Migration

  def change do
    create table(:journals, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true

      add :title, :string, null: false
      add :description, :text
      add :default, :boolean, null: false, default: false

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:journals, [:user_id, :default])
  end
end
