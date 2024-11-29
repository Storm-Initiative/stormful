defmodule Stormful.Repo.Migrations.AddPlanIdToTodo do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :plan_id, references(:plans, on_delete: :delete_all)
    end

    create index(:todos, [:plan_id])
    # INFO: this is a forgotten one, from 2 migrations before
    create index(:thoughts, [:sensical_id])
  end
end
