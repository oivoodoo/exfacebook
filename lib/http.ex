defmodule Exfacebook.Http do
  require Poison
  require Logger

  alias HTTPoison.Response
  alias HTTPoison.Error

  @moduledoc """
  Http requests using `hackney` and decode response using `HTTPoison` to `JSON`.
  """

  @http_options Application.get_env(:exfacebook,
    :http_options,
    [recv_timeout: :infinity,
     timeout: 10000,
     hackney: [timeout: 10000, pool: false]]
  )

  defmodule HttpError do
    @moduledoc false

    @enforce_keys [:message]
    defstruct status_code: nil, message: nil
  end

  @doc false
  def get(url) do
    Logger.info inspect(url)

    case HTTPoison.get(url, [], @http_options) do
      {:ok, %Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, _value} = state -> state
          error -> {:error, %HttpError{message: inspect(error)}}
        end
      {:ok, %Response{status_code: status_code}} ->
        {:error, %HttpError{status_code: status_code, message: "not found resource"}}
      {:error, %Error{reason: reason}} ->
        {:error, "[Http.get] #{reason}"}
      _ ->
        {:error, "[Http.get] 0xDEADBEEF happened"}
    end
  end
end
