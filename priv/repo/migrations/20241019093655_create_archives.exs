defmodule Stormful.Repo.Migrations.CreateArchives do
  use Ecto.Migration

  def change do
    create table(:archives) do
      add :context, :string
      add :color_code, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:archives, [:context, :user_id])
  end
end
