defmodule Stormful.Accounts.Profile do
  @moduledoc """
  Profile schema for user AI-related preferences and settings.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :thought_extraction, :boolean, default: false
    field :timezone, :string, default: "UTC"
    field :greeting_phrase, :string

    belongs_to :user, Stormful.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:thought_extraction, :timezone, :greeting_phrase])
    |> validate_required([])
    |> validate_length(:greeting_phrase, max: 100)
    |> validate_timezone()
  end

  defp validate_timezone(changeset) do
    case get_change(changeset, :timezone) do
      nil ->
        changeset

      timezone ->
        if timezone in Timex.timezones() do
          changeset
        else
          add_error(changeset, :timezone, "is not a valid timezone")
        end
    end
  end
end
