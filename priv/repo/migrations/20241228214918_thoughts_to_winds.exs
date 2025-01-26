defmodule Stormful.Repo.Migrations.ThoughtsToWinds do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # thoughts_query =
    #   from(t in Stormful.Brainstorming.Thought,
    #     where:
    #       not is_nil(t.user_id) and not is_nil(t.sensical_id) and
    #         fragment("length(?)", t.words) <= 255,
    #     select: %{
    #       id: t.id,
    #       words: t.words,
    #       user_id: t.user_id,
    #       sensical_id: t.sensical_id,
    #       inserted_at: t.inserted_at,
    #       updated_at: t.updated_at
    #     },
    #     order_by: [asc: t.inserted_at, asc: t.id]
    #   )

    # total_thoughts = Stormful.Repo.aggregate(Stormful.Brainstorming.Thought, :count)
    # valid_thoughts = Stormful.Repo.aggregate(thoughts_query, :count)

    # IO.puts("""
    # ⚡️ Storm Report ⚡️
    # Total thoughts: #{total_thoughts}
    # Valid thoughts for migration: #{valid_thoughts}
    # Orphaned thoughts being cleared: #{total_thoughts - valid_thoughts}
    # """)

    # # Process in ordered chunks
    # Stormful.Repo.transaction(fn ->
    #   thoughts_query
    #   |> Stormful.Repo.stream()
    #   |> Stream.chunk_every(100)
    #   |> Stream.each(fn chunk ->
    #     winds =
    #       Enum.map(chunk, fn thought ->
    #         %{
    #           id: Ecto.ULID.generate(DateTime.to_unix(thought.inserted_at)),
    #           words: thought.words,
    #           long_words: nil,
    #           user_id: thought.user_id,
    #           sensical_id: thought.sensical_id,
    #           inserted_at: thought.inserted_at,
    #           updated_at: thought.updated_at
    #         }
    #       end)

    #     IO.puts("Inserting #{length(winds)} winds")
    #     Stormful.Repo.insert_all(Stormful.FlowingThoughts.Wind, winds)
    #   end)
    #   |> Stream.run()
    # end)
  end

  def down do
  end
end
