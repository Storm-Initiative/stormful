defmodule Stormful.Repo.Migrations.TempestLogicForSensicalsAndWinds do
  use Ecto.Migration

  def change do
    # we add is_tempest_of to the sensical, to make winds be able to start a sensical as a tempest
    # this is nullable, which'll make it so that we can filter out for our main page or whatever else
    alter table(:sensicals) do
      add :is_tempest_of_id, references(:winds, on_delete: :nilify_all, type: :binary_id)
    end

  end
end
