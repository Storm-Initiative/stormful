defmodule Stormful.Repo.Migrations.CreateSensicals do
  use Ecto.Migration

  def change do
    create table(:sensicals) do
      add :title, :string
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:sensicals, [:user_id])
  end
end
