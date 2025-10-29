defmodule Stormful.AgendaRelated do
  @moduledoc """
  The AgendaRelated context.
  """

  import Ecto.Query, warn: false
  alias Stormful.Utils.TimeRelated
  alias Stormful.ProfileManagement
  alias Stormful.Accounts
  alias Stormful.Repo

  alias Stormful.Agenda.Agenda
  alias Stormful.Agenda.AgendaEvent

  @doc """
  Returns the list of agendas for a user.

  ## Examples

      iex> list_agendas(user_id)
      [%Agenda{}, ...]

  """
  def list_agendas(user_id) do
    Repo.all(
      from a in Agenda,
        where: a.user_id == ^user_id,
        order_by: [desc: a.inserted_at]
    )
  end

  @doc """
  Gets a single agenda.

  Raises `Ecto.NoResultsError` if the Agenda does not exist.

  ## Examples

      iex> get_agenda!(user_id, 123)
      %Agenda{}

      iex> get_agenda!(user_id, 456)
      ** (Ecto.NoResultsError)

  """
  def get_agenda!(user_id, id) do
    Repo.one!(
      from a in Agenda,
        where: a.user_id == ^user_id and a.id == ^id
    )
  end

  @doc """
  Creates an agenda.

  ## Examples

      iex> create_agenda(%{field: value})
      {:ok, %Agenda{}}

      iex> create_agenda(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agenda(attrs \\ %{}) do
    %Agenda{}
    |> Agenda.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  get the user's agenda, if user ain't got one, just create one.
  we gonna handle timing issues with fucking up the user's agendas and confusing them for now.
  cuz I don't want to spend my very precious time on this niche case
  """
  def get_users_agenda(user_id) do
    agenda =
      Repo.one(
        from a in Agenda,
          where: a.user_id == ^user_id
      )

    if agenda do
      agenda
    else
      create_agenda(%{user_id: user_id, name: "Initial"})
      nil
    end
  end

  @doc """
  Updates an agenda.

  ## Examples

      iex> update_agenda(agenda, %{field: new_value})
      {:ok, %Agenda{}}

      iex> update_agenda(agenda, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_agenda(%Agenda{} = agenda, attrs) do
    agenda
    |> Agenda.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an agenda.

  ## Examples

      iex> delete_agenda(agenda)
      {:ok, %Agenda{}}

      iex> delete_agenda(agenda)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agenda(%Agenda{} = agenda) do
    Repo.delete(agenda)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking agenda changes.

  ## Examples

      iex> change_agenda(agenda)
      %Ecto.Changeset{data: %Agenda{}}

  """
  def change_agenda(%Agenda{} = agenda, attrs \\ %{}) do
    Agenda.changeset(agenda, attrs)
  end

  # Agenda Events

  @doc """
  Returns the list of agenda events for an agenda.

  ## Examples

      iex> list_agenda_events(agenda_id)
      [%AgendaEvent{}, ...]

  """
  def list_agenda_events(user_id, agenda_id) do
    Repo.all(
      from ae in AgendaEvent,
        where: ae.agenda_id == ^agenda_id and ae.user_id == ^user_id,
        order_by: [asc: ae.event_date]
    )
  end

  @doc """
  Gets a single agenda event.

  Raises `Ecto.NoResultsError` if the AgendaEvent does not exist.

  ## Examples

      iex> get_agenda_event!(user_id, 123)
      %AgendaEvent{}

      iex> get_agenda_event!(user_id, 456)
      ** (Ecto.NoResultsError)

  """
  def get_agenda_event!(user_id, id) do
    Repo.one!(
      from ae in AgendaEvent,
        where: ae.user_id == ^user_id and ae.id == ^id
    )
  end

  @doc """
  Creates an agenda event.

  ## Examples

      iex> create_agenda_event(%{field: value})
      {:ok, %AgendaEvent{}}

      iex> create_agenda_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agenda_event(user_id, attrs \\ %{}) do
    user = Accounts.get_user!(user_id)
    user_timezone = ProfileManagement.get_user_timezone(user)

    event_date = TimeRelated.fix_date_for_timezone(attrs["event_date"], user_timezone)

    %AgendaEvent{}
    |> AgendaEvent.changeset(
      attrs
      |> Map.put("user_id", user_id)
      |> Map.put("event_date", event_date)
    )
    |> Repo.insert()
  end

  @doc """
  Updates an agenda event.

  ## Examples

      iex> update_agenda_event(agenda_event, %{field: new_value})
      {:ok, %AgendaEvent{}}

      iex> update_agenda_event(agenda_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_agenda_event(%AgendaEvent{} = agenda_event, attrs) do
    agenda_event
    |> AgendaEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an agenda event.

  ## Examples

      iex> delete_agenda_event(agenda_event)
      {:ok, %AgendaEvent{}}

      iex> delete_agenda_event(agenda_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agenda_event(%AgendaEvent{} = agenda_event) do
    Repo.delete(agenda_event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking agenda event changes.

  ## Examples

      iex> change_agenda_event(agenda_event)
      %Ecto.Changeset{data: %AgendaEvent{}}

  """
  def change_agenda_event(%AgendaEvent{} = agenda_event, attrs \\ %{}) do
    AgendaEvent.changeset(agenda_event, attrs)
  end
end
