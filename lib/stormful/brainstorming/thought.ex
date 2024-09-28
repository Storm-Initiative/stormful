defmodule Stormful.Brainstorming.Thought do
  use Ecto.Schema
  import Ecto.Changeset

  def colors do
    [
      "bg-slate-600",
      "bg-gray-600",
      "bg-zinc-600",
      "bg-neutral-600",
      "bg-stone-600",
      "bg-red-600",
      "bg-orange-600",
      "bg-amber-600",
      "bg-yellow-600",
      "bg-lime-600",
      "bg-green-600",
      "bg-emerald-600",
      "bg-teal-600",
      "bg-cyan-600",
      "bg-sky-600",
      "bg-blue-600",
      "bg-indigo-600",
      "bg-violet-600",
      "bg-purple-600",
      "bg-fuchsia-600",
      "bg-ping-600",
      "bg-rose-600",
      "bg-black"
    ]
  end

  schema "thoughts" do
    field :words, :string
    field :archived, :boolean
    field :bg_color, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(thought, attrs) do
    thought
    |> cast(attrs, [:words, :bg_color])
    |> validate_required([:words])
    |> validate_inclusion(:bg_color, colors())
  end
end
