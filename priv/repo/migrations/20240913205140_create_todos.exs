defmodule Stormful.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :title, :string
      add :description, :string
      add :completed_at, :naive_datetime
      add :loose_thought_link, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
