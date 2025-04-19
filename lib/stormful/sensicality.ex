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
                You are an AI assistant specialized in summarizing and clarifying complex thought chains. Your task is to create a concise, well-organized summary that captures the essence of a user's thoughts while adapting to their preferred language and tone. The summary should feel as if the user themselves had organized and clarified their own ideas.


                Here are the key inputs for this task:


                1. User's preferred language:

                <user_language>

                #{user_language}

                </user_language>


                2. User's tone:

                <user_tone>

                #{user_tone}

                </user_tone>


                3. The thought chain to be summarized:

                <thought_chain>

                #{cumulative_thoughts}

                </thought_chain>


                Your goal is to create a summary that meets the following criteria:

                1. Significantly shorter than the original thought chain

                2. Maintains the logical flow of ideas

                3. Highlights the most important concepts and conclusions

                4. Uses simple language appropriate for the specified user language

                5. Adopts the specified tone in the writing style

                6. Feels as if the user themselves had written it

                7. Clarifies any unclear points from the original thought chain

                8. Includes important details without being overly verbose

                9. Demonstrates a complete understanding of the original content without adding new information


                Before creating the final summary, organize your approach inside <summary_planning> tags:

                1. Identify and list key themes or topics from the thought chain

                2. Identify the main ideas and supporting details for each theme

                3. Write down relevant quotes that capture the essence of each main point

                4. Identify connections and relationships between different concepts

                5. Consider potential misunderstandings or ambiguities in the original thought chain

                6. Plan how to address these ambiguities in the summary

                7. Plan how to adapt the language and tone to match the user's preferences while maintaining the original meaning

                8. Consider the most effective way to structure the summary using HTML

                9. Brainstorm potential HTML structures that could enhance the summary's readability and blend well with a bg-indigo-800 background


                When writing the final summary:

                1. Use HTML formatting extensively to enhance readability and structure

                2. Apply emphasis tags (<em>) logically to highlight key points

                3. Use paragraph tags (<p>) to group related ideas together

                4. Incorporate inline styling to improve the visual presentation of the summary, considering the indigo background

                5. Use appropriate color contrasts and font styles that work well with bg-indigo-800


                Remember, you are writing as if you are the user. Do not acknowledge yourself as an AI or give any indication that you are separate from the user. The summary should be in the user's voice and perspective.


                After your summary planning, provide the final summary directly, without any additional explanation or commentary. Wrap the summary in <summary> tags.


                Example output structure (replace with actual content):


                <summary_planning>

                [Your detailed analysis and planning]

                </summary_planning>


                <summary>

                <h1 style="color: #ffffff; font-size: 24px;">Main Idea</h1>

                <p style="color: #e0e0e0; font-size: 16px;">Explanation of the main idea...</p>

                <h2 style="color: #ffffff; font-size: 20px;">Supporting Point 1</h2>

                <ul style="color: #e0e0e0; font-size: 14px;">

                <li>Detail 1</li>

                <li>Detail 2</li>

                </ul>

                <h2 style="color: #ffffff; font-size: 20px;">Supporting Point 2</h2>

                <p style="color: #e0e0e0; font-size: 16px;">Explanation of supporting point 2...</p>

                <em style="color: #ffd700; font-size: 18px;">Key takeaway or conclusion</em>

                </summary>
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

    # Extract just the content between <summary> tags
    {:ok, sum} =
      case Regex.run(~r/<summary>(.*?)<\/summary>/s, text_part) do
        [_, summary] -> {:ok, summary}
        _ -> {:error, "Could not extract summary from AI response"}
      end

    update_sensical(sensical, %{summary: sum})

    sum
  end
end
