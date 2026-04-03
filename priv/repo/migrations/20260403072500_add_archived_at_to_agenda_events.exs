defmodule Stormful.Repo.Migrations.AddArchivedAtToAgendaEvents do
  use Ecto.Migration

  def change do
    alter table(:agenda_events) do
      add :archived_at, :utc_datetime
    end
  end
end
