defmodule Stormful.Repo.Migrations.CreateWinds do
  use Ecto.Migration

  def change do
    create table(:winds, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true

      add :words, :string
      add :long_words, :text
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:winds, [:user_id])
  end
end
