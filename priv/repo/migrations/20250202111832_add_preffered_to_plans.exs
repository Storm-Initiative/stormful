defmodule Stormful.Repo.Migrations.AddPrefferedToPlans do
  use Ecto.Migration

  def change do
    alter table(:plans) do
      add :preferred, :boolean, default: false
    end

    create index(:plans, [:preferred])
  end
end
