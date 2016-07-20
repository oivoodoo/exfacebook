defmodule Exfacebook.Api do
  require Poison
  require Logger

  alias Exfacebook.Http
  alias Exfacebook.Config

  @moduledoc ~S"""
  Basic functions for accessing Facebook API.
  """

  defmodule Params do
    @moduledoc ~S"""
    Facebook allowed to pass specific params in API requests

      * limit - `25` value is default
      * access_token - should be encrypted in case of using in requests for
      authenticated users
      * fields - specify fields to return in response, example: `"id, name"`
    """
    defstruct limit: 25, access_token: nil, fields: ""
  end


  @doc """
  Use get_connections to read feed, home collections.
  """
  def get_connections(id, name, params), do: _request(id, name, params)


  @doc """
  Pagination `next_page` is using response from calls of `get_connections`.

  Example:

      page0 = get_connections(...)
      page1 = page0 |> next_page
      page0 = page1 |> prev_page
  """
  def next_page({:error, _error} = state), do: state
  def next_page({:ok, %{"paging" => %{"next" => url}}}), do: _request(url)
  def next_page({:ok, _response}), do: {:ok, %{"data" => []}}


  @doc false
  def prev_page({:error, _error} = state), do: state
  def prev_page({:ok, %{"paging" => %{"previous" => url}}}), do: _request(url)
  def prev_page({:ok, _response}), do: {:ok, %{"data" => []}}


  @doc false
  def get_object(id, params), do: _request(id, params)


  defp _request(id, params), do:  id |> _make_url(params) |> _request
  defp _request(id, name, params), do: _request(~s(#{id}/#{name}), params)
  defp _request(url), do: Http.get(url)


  defp _auth(%Params{access_token: access_token} = params, secret) do
    Map.put(params, :appsecret_proof, _encrypt(secret, access_token))
  end


  defp _make_url(path, params) do
    params = params |> Map.delete(:__struct__) |> Map.to_list
    path = "#{Config.api_version}/#{path}"
    :hackney_url.make_url("https://graph.facebook.com", path, params)
  end


  defp _encrypt(secret, token) do
    access_token = :crypto.hmac(:sha256, secret, token)
    Base.encode16(access_token, case: :lower)
  end
end
