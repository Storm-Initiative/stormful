defmodule Stormful.FlowingThoughts.Wind do
  @moduledoc false

  alias Stormful.Sensicality.Sensical
  alias Stormful.Journaling.Journal
  alias Stormful.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "winds" do
    field :words, :string
    field :long_words, :string
    belongs_to :user, User
    belongs_to :sensical, Sensical
    belongs_to :journal, Journal, type: Ecto.ULID

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(wind, attrs) do
    wind
    |> cast(attrs, [:words, :long_words, :user_id, :sensical_id, :journal_id])
    |> validate_required([:words, :user_id])
    |> validate_length(:words, min: 1, max: 255)
    |> validate_wind_ownership()
  end

  # Validate that wind belongs to either a sensical OR a journal, not both
  defp validate_wind_ownership(changeset) do
    sensical_id = get_field(changeset, :sensical_id)
    journal_id = get_field(changeset, :journal_id)

    case {sensical_id, journal_id} do
      {nil, nil} ->
        add_error(changeset, :base, "Wind must belong to either a sensical or a journal")

      {_sensical, _journal} when not is_nil(sensical_id) and not is_nil(journal_id) ->
        add_error(changeset, :base, "Wind cannot belong to both a sensical and a journal")

      _ ->
        changeset
    end
  end
end
