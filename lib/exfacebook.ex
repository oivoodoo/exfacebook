defmodule Exfacebook.Http do
  require Poison

  alias HTTPoison.Response
  alias HTTPoison.Error

  @http_options [recv_timeout: :infinity, timeout: 10000, hackney: [timeout: 10000, pool: false]]

  def get(url) do
    case HTTPoison.get(url, [], @http_options) do
      {:ok, %Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, _value} = state -> state
          error -> {:error, error}
        end
      {:ok, %Response{status_code: 404}} ->
        {:error, "[Http.get] not found resource"}
      {:error, %Error{reason: reason}} ->
        {:error, "[Http.get] #{reason}"}
      _ ->
        {:error, "[Http.get] 0xDEADBEEF happened"}
    end
  end
end
