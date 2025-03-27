defmodule Stormful.AiRelated.AnthropicClient do
  defmodule AnthropicTypes do
    # INFO: for now, the message.content does not go like message.content but like message["content"] we gotta fix it somehow
    @type ratelimit_headers ::
            %{
              input_tokens_limit: [String.t()],
              input_tokens_remaining: [String.t()],
              input_tokens_reset: [String.t()],
              output_tokens_limit: [String.t()],
              output_tokens_remaining: [String.t()],
              output_tokens_reset: [String.t()],
              requests_limit: [String.t()],
              requests_remaining: [String.t()],
              requests_reset: [String.t()],
              tokens_limit: [String.t()],
              tokens_remaining: [String.t()],
              tokens_reset: [String.t()]
            }
            | %{String.t() => [String.t()]}

    @type message :: %{
            content: [%{text: String.t(), type: String.t()}],
            id: String.t(),
            model: String.t(),
            role: String.t(),
            stop_reason: String.t(),
            stop_sequence: nil | String.t(),
            type: String.t(),
            usage: %{input_tokens: integer(), output_tokens: integer()}
          }

    @type response :: %{
            status: integer(),
            headers: ratelimit_headers(),
            body: message(),
            trailers: map(),
            private: map()
          }
  end

  def config(:anthropic_api_key) do
    StormfulWeb.Endpoint.config(:anthropic_api_key)
  end

  @base_url "https://api.anthropic.com/v1"

  def base_req(anthropic_version) do
    Req.new(base_url: @base_url)
    |> Req.Request.put_headers([
      {"x-api-key", config(:anthropic_api_key)},
      {"anthropic-version", anthropic_version},
      {"content-type", "application/json"}
    ])
  end

  @type message_content :: %{
          role: String.t(),
          content: String.t()
        }

  @spec use_messages(
          model :: String.t(),
          messages :: list(message_content()),
          max_tokens :: String.t(),
          max_tokens :: integer()
        ) :: AnthropicTypes.response()
  def use_messages(
        model,
        messages,
        system_prompt \\ "You are a helpful assistant",
        max_tokens \\ 512
      ) do
    base_req("2023-06-01")
    |> Req.Request.merge_options(
      json: %{
        "model" => model,
        "system" => system_prompt,
        "max_tokens" => max_tokens,
        "messages" => messages
      }
    )
    |> Req.post!(url: "/messages", receive_timeout: 120_000)
  end
end
