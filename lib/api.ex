defmodule Exfacebook.Api do
  require Poison
  require Logger

  alias Exfacebook.Http
  alias Exfacebook.Config
  alias Exfacebook.Params
  alias Exfacebook.Error

  @moduledoc ~S"""
  Basic functions for accessing Facebook API.
  """

  @doc """
  Use get_connections to read feed, home collections.
  """
  @spec get_connections(string, string | binary, Params.t) :: {:ok, Map.t} | {:error, Error.t}
  def get_connections(id, name, params), do: _request(id, name, params)


  @doc """
  Pagination `next_page` is using response from calls of `get_connections`.

  Example:

      page0 = get_connections(...)
      page1 = page0 |> next_page
      page0 = page1 |> prev_page
  """
  @spec next_page({:ok, Map.t} | {:error, Error.t}) :: {:ok, Map.t} | {:error, Error.t}
  def next_page({:error, _error} = state), do: state
  def next_page({:ok, %{"paging" => %{"next" => url}}}), do: _request(url)
  def next_page({:ok, _response}), do: {:ok, %{"data" => []}}


  @doc false
  @spec next_page({:ok, Map.t} | {:error, Error.t}) :: {:ok, Map.t} | {:error, Error.t}
  def prev_page({:error, _error} = state), do: state
  def prev_page({:ok, %{"paging" => %{"previous" => url}}}), do: _request(url)
  def prev_page({:ok, _response}), do: {:ok, %{"data" => []}}


  @doc false
  @spec get_object(String.t, Params.t) :: {:ok, Map.t} | {:error, Error.t}
  def get_object(id, params) do
    params = Map.delete(params, :limit)
    _request(id, params)
  end


  defp _request(id, params), do:  id |> _make_url(params) |> _request
  defp _request(id, name, params), do: _request(~s(#{id}/#{name}), params)
  defp _request(url), do: Http.get(url)


  defp _auth(params), do: _encrypt(params, Config.id, Config.secret)


  defp _make_url(path, params) do
    params = params |> _auth |> Map.delete(:__struct__) |> Map.to_list
    path = "#{Config.api_version}/#{path}"
    :hackney_url.make_url("https://graph.facebook.com", path, params)
  end


  defp _encrypt(%Params{access_token: nil} = params, _, nil), do: params
  defp _encrypt(%Params{access_token: nil} = params, id, secret) do
    %Params{params | access_token: "#{id}|#{secret}"}
  end
  defp _encrypt(%Params{access_token: access_token} = params, _, secret) do
    access_token = :crypto.hmac(:sha256, secret, access_token)
    appsecret_proof = Base.encode16(access_token, case: :lower)
    Map.put(params, :appsecret_proof, appsecret_proof)
  end
end
