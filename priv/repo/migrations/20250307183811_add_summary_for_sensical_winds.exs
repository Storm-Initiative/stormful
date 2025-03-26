defmodule Stormful.Repo.Migrations.AddSummaryForSensicalWinds do
  use Ecto.Migration

  def change do
    alter table(:sensicals) do
      add :summary, :text
    end
  end
end
