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

    user_language = "Whatever language they using > 60%"
    user_tone = "How they speak 80% of the time"

    response_from_ai =
      AnthropicClient.use_messages(
        "claude-3-7-sonnet-20250219",
        [
          %{
            role: "user",
            content: [
              %{
                type: "text",
                text: """
                You are an AI assistant tasked with summarizing a long, concatenated thought chain. Your goal is to create a single, concise summary that captures the essence of the original thoughts while adapting it to the user's language and tone. This summary should feel as if the user themselves had organized and clarified their own thoughts.

                Here is the thought chain you need to summarize:

                <thought_chain>
                #{cumulative_thoughts}
                </thought_chain>

                The user's preferred language is:
                <user_language>
                #{user_language}
                </user_language>

                The user's tone is:
                <user_tone>
                #{user_tone}
                </user_tone>

                Now, create a single, concise summary based on your analysis. Your summary should:

                1. Be significantly shorter than the original thought chain
                2. Maintain the logical flow of ideas
                3. Highlight the most important concepts and conclusions
                4. Use simple language appropriate for the specified user language
                5. Adopt the specified tone in your writing style
                6. Feel as if the user themselves had written it, making sense of their own thoughts
                7. Clarify any unclear points from the original thought chain
                8. Include important details without being overly verbose
                9. Demonstrate a complete understanding of the original content without adding new information

                Present your summary within <summary> tags. Use only plain HTML, avoiding any Markdown elements. Also, you should make use of regular HTML elements to provide extra attention to details and stuff like that, using inline styling is extra appreciated. Please do remember that the app has bg-indigo-800 TailwindCSS class, this might be important for accessibility. Here's an example of the expected format:

                [Your concise summary goes here, written in simple language matching the user's tone, as if they had organized their own thoughts. The summary should flow logically, highlight key points, and clarify any original unclear points while maintaining the essence of the original thought chain. If user has some logical writing mistakes, like invalid '.', ','s have them fixed along the way, without butchering the meaning.]

                Remember, your goal is to provide a clear, concise, and accessible summary of the original thought chain that feels authentic to the user's voice and perspective. Aim for a summary that the user would feel comfortable presenting as their own organized thoughts.

                Never ever give me acknowledgement; remember, you are talking like the user, as the user.
                """
              }
            ]
          }
        ],
        "",
        10_000
      )

    content = response_from_ai.body["content"]
    [meaty_part] = content
    text_part = meaty_part["text"]

    update_sensical(sensical, %{summary: text_part})

    text_part
  end
end
