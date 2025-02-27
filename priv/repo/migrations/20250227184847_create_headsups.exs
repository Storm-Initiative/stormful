defmodule Stormful.Repo.Migrations.CreateHeadsups do
  use Ecto.Migration

  def change do
    create table(:headsups) do
      add :title, :string
      add :description, :string

      add :sensical_id, references(:sensicals, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
