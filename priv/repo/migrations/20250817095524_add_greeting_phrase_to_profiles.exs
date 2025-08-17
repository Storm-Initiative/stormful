defmodule Stormful.Repo.Migrations.AddGreetingPhraseToProfiles do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :greeting_phrase, :string
    end
  end
end
