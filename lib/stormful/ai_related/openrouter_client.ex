defmodule Stormful.AiRelated.OpenRouterClient do
  @moduledoc """
  Basic OpenRouter API client for completion requests.
  Reads API key and base URL from environment variables for security.

  Required environment variables:
  - OPENROUTER_API_KEY: Your OpenRouter API key
  - OPENROUTER_BASE_URL: Base URL (optional, defaults to https://openrouter.ai/api/v1)
  """

  @default_base_url "https://openrouter.ai/api/v1"

  @doc """
  Make a completion request to OpenRouter API.

  ## Parameters
  - model: The model ID to use
  - prompt: The text prompt to complete
  - opts: Optional parameters (max_tokens, temperature, etc.)

  ## Example
      iex> OpenRouterClient.complete("openai/gpt-3.5-turbo", "Hello world")
      {:ok, %{"id" => "...", "choices" => [%{"text" => "..."}]}}
  """
  def complete(model, prompt, opts \\ []) do
    with {:ok, api_key} <- get_api_key(),
         {:ok, base_url} <- get_base_url() do
      url = "#{base_url}/completions"

      payload =
        %{
          "model" => model,
          "prompt" => prompt
        }
        |> maybe_add_optional_params(opts)

      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      case Req.post(url, json: payload, headers: headers) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: status_code, body: body}} ->
          {:error, {:http_error, status_code, body}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Convenience function to get just the text from the first choice.
  """
  def complete_text(model, prompt, opts \\ []) do
    case complete(model, prompt, opts) do
      {:ok, %{"choices" => [%{"text" => text} | _]}} -> {:ok, text}
      {:ok, response} -> {:error, {:unexpected_response, response}}
      error -> error
    end
  end

  # Private function to get API key from environment
  defp get_api_key do
    case System.get_env("OPENROUTER_API_KEY") do
      nil -> {:error, :missing_api_key}
      "" -> {:error, :empty_api_key}
      api_key -> {:ok, api_key}
    end
  end

  # Private function to get base URL from environment or use default
  defp get_base_url do
    base_url = System.get_env("OPENROUTER_BASE_URL", @default_base_url)
    {:ok, base_url}
  end

  # Private function to add optional parameters to the payload
  defp maybe_add_optional_params(payload, []), do: payload

  defp maybe_add_optional_params(payload, opts) do
    Enum.reduce(opts, payload, fn {key, value}, acc ->
      case key do
        :max_tokens when is_integer(value) -> Map.put(acc, "max_tokens", value)
        :temperature when is_number(value) -> Map.put(acc, "temperature", value)
        :top_p when is_number(value) -> Map.put(acc, "top_p", value)
        :stream when is_boolean(value) -> Map.put(acc, "stream", value)
        :seed when is_integer(value) -> Map.put(acc, "seed", value)
        :user when is_binary(value) -> Map.put(acc, "user", value)
        _ -> acc
      end
    end)
  end
end
