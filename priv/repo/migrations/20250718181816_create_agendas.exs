defmodule Stormful.Repo.Migrations.CreateAgendas do
  use Ecto.Migration

  def change do
    create table(:agendas, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true

      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:agendas, [:user_id, :name])
  end
end
