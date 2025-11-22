defmodule Stormful.ProfileManagement do
  @moduledoc """
  The ProfileManagement context for handling user AI-related preferences and settings.
  """

  import Ecto.Query, warn: false
  alias Stormful.Repo
  alias Stormful.Accounts.{User, Profile}
  use Phoenix.VerifiedRoutes, endpoint: StormfulWeb.Endpoint, router: StormfulWeb.Router

  @doc """
  Gets a user's profile by user ID.

  ## Examples

      iex> get_user_profile(user_id)
      %Profile{}

      iex> get_user_profile(invalid_user_id)
      nil

  """
  def get_user_profile(user_id) do
    Repo.get_by(Profile, user_id: user_id)
  end

  @doc """
  Gets or creates a user's profile.

  ## Examples

      iex> get_or_create_user_profile(user)
      %Profile{}

  """
  def get_or_create_user_profile(%User{} = user) do
    case get_user_profile(user.id) do
      nil ->
        case create_user_profile(user) do
          {:ok, profile} -> profile
          {:error, _changeset} -> nil
        end

      profile ->
        profile
    end
  end

  @doc """
  Creates a profile for a user.

  ## Examples

      iex> create_user_profile(user, %{thought_extraction: true})
      {:ok, %Profile{}}

      iex> create_user_profile(user, %{invalid: value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_profile(%User{} = user, attrs \\ %{}) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a user's profile.

  ## Examples

      iex> update_user_profile(profile, %{thought_extraction: false})
      {:ok, %Profile{}}

      iex> update_user_profile(profile, %{invalid: value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile changes.

  ## Examples

      iex> change_user_profile(profile)
      %Ecto.Changeset{data: %Profile{}}

  """
  def change_user_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, attrs)
  end

  @doc """
  Gets a user's timezone from their profile.

  ## Examples

      iex> get_user_timezone(user)
      "America/New_York"

      iex> get_user_timezone(invalid_user)
      "UTC"

  """
  def get_user_timezone(%User{} = user) do
    profile = get_or_create_user_profile(user)
    profile.timezone
  end

  @doc """
  get where the user should be landed at, as a ~p sigil-ed str whatever

  ## Examples

      iex> get_the_destination_for_the_user_to_land(user)
      ~p"/journal"

      iex> get_the_destination_for_the_user_to_land(user)
      ~p"/sensicality/1"
  """
  def get_the_destination_for_the_user_to_land(%User{} = user) do
    profile = get_or_create_user_profile(user)
    lands_initially = profile.lands_initially
    latest_visited_sensical_id = profile.latest_visited_sensical_id

    if(
      lands_initially == "latest_sensical" &&
        latest_visited_sensical_id
    ) do
      ~p"/sensicality/#{latest_visited_sensical_id}"
    else
      ~p"/journal"
    end
  end
end
