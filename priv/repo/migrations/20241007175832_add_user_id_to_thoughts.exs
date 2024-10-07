defmodule Stormful.Repo.Migrations.AddUserIdToThoughts do
  use Ecto.Migration

  def change do
    alter table(:thoughts) do
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
