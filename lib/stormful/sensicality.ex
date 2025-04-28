defmodule Stormful.Sensicality do
  @moduledoc """
  The Sensicality context.
  """

  import Ecto.Query, warn: false
  alias Stormful.AiRelated.AnthropicClient
  alias Stormful.FlowingThoughts
  alias Stormful.Planning.Plan
  alias Stormful.Repo

  alias Stormful.Sensicality.Sensical

  @doc """
  Returns the list of sensicals.

  ## Examples

      iex> list_sensicals()
      [%Sensical{}, ...]

  """
  def list_sensicals(user_id) do
    Repo.all(
      from s in Sensical, where: s.user_id == ^user_id, order_by: [desc: s.inserted_at], limit: 20
    )
  end

  @doc """
  Gets a single sensical. Authorized by user id as first arg

  Raises `Ecto.NoResultsError` if the Sensical does not exist.

  ## Examples

      iex> get_sensical!(456, 123)
      %Sensical{}

      iex> get_sensical!(123, 456)
      ** (Ecto.NoResultsError)

  """
  def get_sensical!(user_id, id, with_plans \\ true) do
    # we can do wild shit like w.id with ULID, its truly powerful :raised_fist:

    if with_plans do
      plans_query = from p in Plan, order_by: p.inserted_at

      Repo.one!(
        from s in Sensical,
          where: s.user_id == ^user_id and s.id == ^id,
          preload: [plans: ^plans_query]
      )
    else
      Repo.one!(
        from s in Sensical,
          where: s.user_id == ^user_id and s.id == ^id
      )
    end
  end

  @doc """
  Creates a sensical.

  ## Examples

      iex> create_sensical(%{field: value})
      {:ok, %Sensical{}}

      iex> create_sensical(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sensical(attrs \\ %{}) do
    %Sensical{}
    |> Sensical.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sensical.

  ## Examples

      iex> update_sensical(sensical, %{field: new_value})
      {:ok, %Sensical{}}

      iex> update_sensical(sensical, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sensical(%Sensical{} = sensical, attrs) do
    sensical
    |> Sensical.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sensical.

  ## Examples

      iex> delete_sensical(sensical)
      {:ok, %Sensical{}}

      iex> delete_sensical(sensical)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sensical(%Sensical{} = sensical) do
    Repo.delete(sensical)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sensical changes.

  ## Examples

      iex> change_sensical(sensical)
      %Ecto.Changeset{data: %Sensical{}}

  """
  def change_sensical(%Sensical{} = sensical, attrs \\ %{}) do
    Sensical.changeset(sensical, attrs)
  end

  def summarize_sensical(user_id, sensical_id) do
    winds = FlowingThoughts.list_winds_by_sensical(sensical_id, user_id)
    sensical = get_sensical!(user_id, sensical_id, false)

    cumulative_thoughts =
      winds
      |> Enum.map(fn wind -> "#{wind.words}\n" end)

    # or you can run a detector on cumulative_thoughts
    user_language = "auto"

    # or auto-detect via NLP later if you want
    user_tone = "raw, introspective, chaotic but poetic"

    theme = """
    Stormy -> moody, kinetic words, metaphors like 'thoughts crashing like thunder', maybe even flashes of tension, use of deep blues/grays in implied tone.
    """

    prompt = """
    You are an expert in analyzing complex thought processes and presenting them in a visually structured format. Your task is to generate a summary of a thought chain using semantic HTML with inline styling, optimized for readability on a dark background.

    Carefully analyze the following thought chain:

    <thought_chain>
    #{cumulative_thoughts}
    </thought_chain>

    <user_language>#{user_language}</user_language>
    <user_tone>#{user_tone}</user_tone>
    <theme>#{theme}</theme>

    <imagery_style>
    Use imagery and comparisons that match the theme. Don't just tell — make the summary feel like it's from the storm itself.
    </imagery_style>

    Your task:
    1. Identify core themes and main ideas.
    2. Map logical connections.
    3. Break into hierarchy.
    4. Pick recurring imagery/metaphors.
    5. Choose HTML elements and styles for dark-mode readability.
    6. Use user's tone and speech style authentically.
    7. Never refer to yourself or the user — just deliver the summary.
    8. Make it semantic and accessible.

    Requirements:
    - Use HTML5 semantic tags like <header>, <main>, <section>, <article>, <p>, <ul>, <strong>.
    - Add inline styles: readable colors (grays, cool blues), spacing, smooth fonts.
    - Add nice icons/svgs for eye candy.
    - Make it beautiful on a dark UI.
    - Summary must be tight, not bloated, but the content should be there(maybe expandable) if user wants to go deeper.
    - Use theme emotionally, but do not overdo it — little metaphors, a bit of ideas from roundabouts, flashes of insights, maybe jokes and icons?
    - Do not overdo the theme, it shouldn't kill the idea, it should be a nice annotation that'd make the reader stay and continue.

    Deliver your output wrapped in <summary>...</summary>
    """

    response_from_ai =
      AnthropicClient.use_messages(
        "claude-3-7-sonnet-20250219",
        [
          %{
            role: "user",
            content: [
              %{
                type: "text",
                text: prompt
              }
            ]
          }
        ],
        "",
        8192
      )

    content = response_from_ai.body["content"]
    [meaty_part] = content
    text_part = meaty_part["text"]

    update_sensical(sensical, %{summary: text_part})

    text_part
  end
end
