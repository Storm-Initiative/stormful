defmodule Stormful.Repo.Migrations.CreateAgendaEvents do
  use Ecto.Migration

  def change do
    create table(:agenda_events, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true

      add :the_event, :string, null: false
      add :event_date, :utc_datetime, null: false
      add :agenda_id, references(:agendas, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:agenda_events, [:agenda_id, :the_event, :event_date])
  end
end
