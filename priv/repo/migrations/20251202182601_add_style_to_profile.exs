defmodule Stormful.Repo.Migrations.AddStyleToProfile do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :style, :string, default: "storm"
    end
  end
end
