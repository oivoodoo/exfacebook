defmodule Exfacebook.Http do
  require Poison
  require Logger

  alias HTTPoison.Response
  alias Exfacebook.Error

  @type success :: {:ok, Map.t}
  @type error  :: {:error, Error.t}

  @moduledoc """
  Http requests using `hackney` and decode response using `HTTPoison` to `JSON`.
  """

  @http_options Application.get_env(:exfacebook,
    :http_options,
    [recv_timeout: :infinity,
     timeout: 10000,
     hackney: [timeout: 10000, pool: false]]
  )

  @form_headers %{"Content-type" => "application/x-www-form-urlencoded"}

  @doc """
  Make get request and return JSON response as dictionary.
  """
  @spec get(String) :: success | error
  def get(url) do
    Logger.debug("[Exfacebook.Http.get] url: #{inspect(url)}")
    HTTPoison.get(url, [], @http_options) |> _handle_error
  end

  @spec post(String, Map.t) :: success | error
  def post(url, data \\ []) do
    body = if data != [], do: {:form, data}, else: []
    response = HTTPoison.post(url, body, @form_headers, @http_options)
    Logger.debug "[Facebook.Api.post] response: #{inspect(response)}"
    response |> _handle_error
  end

  @spec delete(String) :: success | error
  def delete(url) do
    response = HTTPoison.delete(url, @form_headers, @http_options)
    Logger.debug "[Facebook.Api.post] response: #{inspect(response)}"
    response |> _handle_error
  end

  defp _handle_error(response) do
    case response do
      {:ok, %Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, _value} = state -> state
          error -> {:error, %Error{message: inspect(error)}}
        end
      {:ok, %Response{status_code: status_code}} ->
        {:error, %Error{status_code: status_code, message: "not found resource"}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %Error{message: inspect(reason)}}
      _ ->
        {:error, %Error{message: "0xDEADBEEF happened"}}
    end
  end
end
