defmodule Stormful.Repo.Migrations.AddBgColorToThoughts do
  use Ecto.Migration

  def change do
    alter table(:thoughts) do
      add :bg_color, :string, default: "bg-black"
    end
  end
end
