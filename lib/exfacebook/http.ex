defmodule Exfacebook.Http do
  @moduledoc """
  HTTP requests using HTTPoison. Responses are decoded as JSON maps.
  """

  require Logger

  alias HTTPoison.Response
  alias Exfacebook.Error

  @type success :: {:ok, map()}
  @type error :: {:error, Error.t()}

  @form_headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  @doc """
  Make a GET request and return the JSON body as a map.
  """
  @spec get(String.t()) :: success | error
  def get(url) do
    Logger.debug("[Exfacebook.Http.get] url: #{redact(url)}")
    HTTPoison.get(url, [], http_options()) |> handle_response()
  end

  @spec post(String.t(), term()) :: success | error
  def post(url, body \\ nil) do
    Logger.debug("[Exfacebook.Http.post] url: #{redact(url)}")
    HTTPoison.post(url, body, @form_headers, http_options()) |> handle_response()
  end

  @spec delete(String.t()) :: success | error
  def delete(url) do
    Logger.debug("[Exfacebook.Http.delete] url: #{redact(url)}")
    HTTPoison.delete(url, @form_headers, http_options()) |> handle_response()
  end

  @doc false
  @spec handle_response(tuple()) :: success | error
  def handle_response({:ok, %Response{status_code: status_code, body: body}}) do
    decode_graph_response(status_code, body)
  end

  def handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, %Error{message: inspect(reason)}}
  end

  def handle_response(_other) do
    {:error, %Error{message: "unexpected HTTP response"}}
  end

  @doc false
  @spec decode_graph_response(integer(), String.t() | nil) :: success | error
  def decode_graph_response(status_code, body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"error" => error}} when is_map(error) ->
        {:error, Error.from_graph(status_code, error, body)}

      {:ok, decoded} when status_code in 200..299 ->
        {:ok, decoded}

      {:ok, decoded} ->
        {:error, %Error{status_code: status_code, message: inspect(decoded)}}

      {:error, decode_error} when status_code in 200..299 ->
        {:error, %Error{status_code: status_code, message: Exception.message(decode_error)}}

      {:error, _} ->
        {:error, %Error{status_code: status_code, message: body}}
    end
  end

  def decode_graph_response(status_code, _body) do
    {:error, %Error{status_code: status_code, message: "empty response body"}}
  end

  defp http_options do
    Application.get_env(:exfacebook, :http_options,
      recv_timeout: :infinity,
      timeout: 10_000,
      hackney: [timeout: 10_000, pool: false]
    )
  end

  defp redact(url) when is_binary(url) do
    Regex.replace(
      ~r/((?:access_token|appsecret_proof|client_secret|fb_exchange_token)=)[^&]*/i,
      url,
      "\\1[REDACTED]"
    )
  end

  defp redact(other), do: inspect(other)
end
