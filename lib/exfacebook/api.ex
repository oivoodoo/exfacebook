defmodule Exfacebook.Api do
  require Poison
  require Logger

  alias Exfacebook.Http
  alias Exfacebook.Config
  alias Exfacebook.Params
  alias Exfacebook.Error

  @type name :: String.t | binary
  @type id :: String.t | binary
  @type success :: {:ok, Map.t}
  @type error  :: {:error, Error.t}
  @type api :: List.t
  @type body :: Map.t

  @moduledoc ~S"""
  Basic functions for accessing Facebook API.
  """

  @doc """
  Use `get_connections` to read feed, home collections.

  Example:

    {:ok, %{"data" => collection}} = get_connections(:me, :feed, %Params{fields: "id, name"})
  """
  @spec get_connections(id, name, Params.t) :: success | error
  def get_connections(id, name, params), do: _get(id, name, params)


  @doc """
  Use `get_connections` for getting collection using batch Facebook API.
  """
  @spec get_connections(api, id, name, Params.t) :: Map.t
  def get_connections(api, id, name, params) do
    relative_url = params |> _make_url_batch("#{id}/#{name}")
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end


  @doc ~S"""
  Getting list of subscriptions for app, we don't need to use user access
  token, it requires to have only app_id and secret.
  """
  @spec list_subscriptions(Params.t) :: success | error
  def list_subscriptions(params) do
    params = params |> Map.delete(:limit) |> Map.delete(:access_token)
    _get(Config.id, :subscriptions, params)
  end


  @doc """
  Pagination `next_page` is using response from calls of `get_connections`.

  Example:

      page0 = get_connections(...)
      page1 = page0 |> next_page
      page0 = page1 |> prev_page
  """
  @spec next_page(success | error) :: success | error
  def next_page({:error, _error} = state), do: state
  def next_page({:ok, %{"paging" => %{"next" => url}}}), do: _get(url)
  def next_page({:ok, _response}), do: {:ok, %{"data" => []}}

  @spec next_page(api, success | error) :: success | error
  def next_page(api, {:error, _error}), do: api
  def next_page(api, {:ok, %{"paging" => %{"next" => url}}}) do
    url = String.replace(url, "https://graph.facebook.com", "")
    api ++ [%{"method" => "GET", "relative_url" => url}]
  end
  def next_page(api, {:ok, _response}), do: api


  @doc false
  @spec prev_page(success | error) :: success | error
  def prev_page({:error, _error} = state), do: state
  def prev_page({:ok, %{"paging" => %{"previous" => url}}}), do: _get(url)
  def prev_page({:ok, _response}), do: {:ok, %{"data" => []}}

  @spec prev_page(api, success | error) :: success | error
  def prev_page(api, {:error, _error}), do: api
  def prev_page(api, {:ok, %{"paging" => %{"previous" => url}}}) do
    url = String.replace(url, "https://graph.facebook.com", "")
    api ++ [%{"method" => "GET", "relative_url" => url}]
  end
  def prev_page(api, {:ok, _response}), do: api


  @doc false
  def batch(data, params) do
    # app `id|secret` or user `access_token`
    params = _auth(params)

    data = [
      batch: Poison.encode!(data),
      access_token: params.access_token,
    ]

    Http.post("https://graph.facebook.com", data) |> _handle_batch
  end

  defp _handle_batch({:error, _} = s), do: s
  defp _handle_batch({:ok, responses}), do: _handle_batch(responses, [])
  defp _handle_batch([], collector), do: collector
  defp _handle_batch([response | tail], collector) do
    response = response |> _process_batch
    _handle_batch(tail, [response] ++ collector)
  end

  defp _process_batch(%{"body" => body, "code" => 200}), do: {:ok, Poison.decode!(body)}
  defp _process_batch(%{"body" => body, "code" => 201}), do: {:ok, Poison.decode!(body)}
  defp _process_batch(%{"body" => body, "code" => code}), do: {:error, %Error{status_code: code, message: body}}


  @doc ~S"""
  Use `get_object` for getting object related attributes

  Example:

    {:ok, %{"id" => id, "name" => name}} = get_object(:me, %Params{access_token: "access-token", fields: "id, name"})
  """
  @spec get_object(id, Params.t) :: success | error
  def get_object(id, params) do
    params = Map.delete(params, :limit)
    _get(id, params)
  end

  @doc """
  Use `get_object` for getting object related attributes as part of batch API.
  """
  @spec get_object(api, id, Params.t) :: Map.t
  def get_object(api, id, params) do
    relative_url = Map.delete(params, :limit) |> _make_url_batch(id)
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end


  @doc ~S"""
  Use `put_connections` for posting messages or other update actions.

  Example:
      put_connections(:me, :feed, %Params{access_token: "access-token"}, %{message: "message-example"})
  """
  @spec put_connections(id, name, Params.t, body) :: success | error
  def put_connections(id, name, params, body \\ %{}) do
    params = Map.delete(params, :limit)
    body = Map.to_list(body)
    _post(id, name, params, body)
  end


  @doc """
  Use `put_connections` for posting messages or other update actions.
  """
  @spec put_connections(api, id, name, Params.t, body) :: success | error
  def put_connections(api, id, name, params, body) do
    relative_url = params |> _make_url_batch("#{id}/#{name}")
    body = body
    |> Enum.map(fn({key, value}) -> "#{key}=#{value}" end)
    |> Enum.join("&amp;")
    api ++ [%{"method" => "POST", "relative_url" => relative_url, "body" => body}]
  end


  defp _make_url_batch(params, path) do
    path = "#{Config.api_version}/#{path}"
    :hackney_url.make_url("", path, _batch_prepare(params))
  end


  defp _get(id, params), do:  id |> _make_url(params) |> _get
  defp _get(id, name, params), do: _get(~s(#{id}/#{name}), params)
  defp _get(url), do: Http.get(url)

  defp _post(id, params, body), do:  id |> _make_url(params) |> _post(body)
  defp _post(id, name, params, body), do: _post(~s(#{id}/#{name}), params, body)
  defp _post(url, body)  do
    Logger.info "_post"
    Logger.info url
    Http.post(url, body)
  end


  defp _make_url(path, params) do
    path = "#{Config.api_version}/#{path}"
    :hackney_url.make_url("https://graph.facebook.com", path, _prepare(params))
  end


  defp _prepare(params), do: params |> _auth |> Map.delete(:__struct__) |> Map.to_list
  defp _batch_prepare(params), do: params |> Map.delete(:access_token) |> Map.delete(:__struct__) |> Map.to_list


  defp _auth(params), do: _encrypt(params, Config.id, Config.secret)


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
