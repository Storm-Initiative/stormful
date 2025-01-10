defmodule Stormful.Repo.Migrations.RemoveUnusedTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:thoughts)
    drop_if_exists table(:boards)
    drop_if_exists table(:archives)
  end
end
