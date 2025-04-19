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
                You are an expert in analyzing complex thought processes and presenting them in a visually structured format. Your task is to generate a summary of a thought chain using semantic HTML with inline styling, optimized for readability on a dark background.


                First, carefully read through the following thought chain:


                <thought_chain>

                #{cumulative_thoughts}

                </thought_chain>


                Before creating the final summary, break down the thought chain in <thought_chain_breakdown> tags. Consider the following points:


                1. List out the main topics or themes present in the thought chain.

                2. Identify key relationships or connections between these topics.

                3. Create a hierarchical outline of the thought chain's structure.

                4. Note any recurring patterns or ideas throughout the thought chain.

                5. Suggest appropriate semantic HTML elements for each level of the hierarchy.

                6. Consider inline styling choices that will enhance readability on a dark background.


                After your breakdown, generate a coherent and concise summary that captures the essence of the thought process. Use semantic HTML5 elements to structure your summary, and apply inline styling to enhance readability and highlight important points. Ensure that your color choices work well on a dark background.


                Requirements for your HTML summary:

                1. Use semantic HTML5 elements such as <header>, <main>, <section>, <article>, <p>, <ul>, <ol>, <li>, <strong>, <em>, etc.

                2. Apply inline styles using the style attribute. Focus on colors, fonts, margins, and other visual enhancements that work well on a dark background.

                3. Ensure the HTML structure reflects the logical flow of ideas in the thought chain.

                4. The summary should be concise yet comprehensive, capturing the key points and relationships between ideas.


                Present your final summary within <summary> tags. Here's an example of the expected structure (note that this is just a structural example and does not reflect the content of your specific thought chain):


                <summary>

                <header style="color: #e0e0e0; font-family: Arial, sans-serif;">

                <h1 style="font-size: 24px; margin-bottom: 10px;">Thought Chain Summary</h1>

                </header>


                <main style="color: #cccccc;">

                <section>

                <h2 style="color: #66ccff; font-size: 20px;">Key Insights</h2>

                <ul style="list-style-type: circle; margin-left: 20px;">

                <li style="margin-bottom: 5px;">Important point 1</li>

                <li style="margin-bottom: 5px;">Important point 2</li>

                </ul>

                </section>



                <article>

                <h3 style="color: #66ff99; font-size: 18px;">Main Idea</h3>

                <p style="line-height: 1.5; margin-bottom: 15px;">Explanation of the main idea...</p>

                </article>

                </main>

                </summary>


                Now, proceed with your breakdown and summary of the provided thought chain.
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
