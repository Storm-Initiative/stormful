defmodule Stormful.Repo.Migrations.AddLandingPageOptionsAndStuff do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :lands_initially, :string
      add :latest_visited_sensical_id, :string
    end

    create index(:profiles, :latest_visited_sensical_id)
  end
end
