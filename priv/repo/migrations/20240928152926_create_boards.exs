defmodule Stormful.Repo.Migrations.CreateBoards do
  use Ecto.Migration

  def change do
    create table(:boards) do
      add :title, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
