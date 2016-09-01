defmodule Exfacebook.Api do
  require Poison
  require Logger

  alias Exfacebook.Http
  alias Exfacebook.Config
  alias Exfacebook.Error

  @type name :: String.t | binary
  @type id :: String.t | binary
  @type success :: {:ok, Map.t}
  @type error  :: {:error, Error.t}
  @type api :: List.t
  @type body :: Map.t
  @type params :: Map.t
  @type file :: String.t | Map.t
  @type access_token :: String.t

  @moduledoc ~S"""
  Basic functions for accessing Facebook API.
  """

  @doc """
  Use `get_connections` to read feed, home collections.

  Example:

    {:ok, %{"data" => collection}} = get_connections(:me, :feed, %{fields: "id, name"})
  """
  @spec get_connections(id, name, params) :: success | error
  def get_connections(id, name, params) do
    params = Map.put_new(params, :limit, 25)
    _get(id, name, params)
  end


  @doc """
  Use `get_connections` for getting collection using batch Facebook API.
  """
  @spec get_connections(api, id, name, params) :: Map.t
  def get_connections(api, id, name, params) do
    relative_url = _make_url_batch(params, "#{id}/#{name}")
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end


  @doc ~S"""
  Getting list of subscriptions for app, we don't need to use user access
  token, it requires to have only app_id and secret.
  """
  @spec list_subscriptions(params) :: success | error
  def list_subscriptions(params) do
    params = params |> Map.delete(:access_token)
    _get(Config.id, :subscriptions, params)
  end


  @doc ~S"""
  Subscribe to real time updates to object.

  `callback_url` - https api endpoint to receive real time updates.
  `verify_token` - token to verify post request from facebook with updates.
  `fields` - 'friends, feed' as an example.
  """
  @spec subscribe(id, String.t, String.t, String.t) :: success | error
  def subscribe(id, fields, callback_url, verify_token \\ nil) do
    params = %{
      object: id,
      callback_url: callback_url,
      fields: fields,
    } |> _assign_verify_token(verify_token)

    _post(:subscriptions, params, {:form, []})
  end

  @doc ~S"""
  `id` - id of object to unsubscribe, in case if developer passed `nil`
  unsubscribe would apply for all subscriptions for facebook app.
  """
  @spec unsubscribe(id) :: success | error
  def unsubscribe(id) do
    params = %{object: id}
    _delete(:subscriptions, params)
  end

  defp _assign_verify_token(params, nil), do: params
  defp _assign_verify_token(params, token), do: Map.put(params, :verify_token, token)


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

  @doc false
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

  @doc false
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

    Http.post("https://graph.facebook.com", {:form, data}) |> _handle_batch
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

    {:ok, %{"id" => id, "name" => name}} = get_object(:me, %{access_token: "access-token", fields: "id, name"})
  """
  @spec get_object(id, params) :: success | error
  def get_object(id, params), do: _get(id, params)

  @doc """
  Use `get_object` for getting object related attributes as part of batch API.
  """
  @spec get_object(api, id, params) :: Map.t
  def get_object(api, id, params) do
    relative_url = _make_url_batch(params, id)
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end


  @doc ~S"""
  Use `put_connections` for posting messages or other update actions.

  Example:
      put_connections(:me, :feed, %{access_token: "access-token"}, %{message: "message-example"})
  """
  @spec put_connections(id, name, params, body) :: success | error
  def put_connections(id, name, params, body \\ %{}) do
    body = Map.to_list(body)
    _post(id, name, params, {:form, body})
  end


  @doc """
  Use `put_connections` for posting messages or other update actions.
  """
  @spec put_connections(api, id, name, params, body) :: success | error
  def put_connections(api, id, name, params, body) do
    relative_url = params |> _make_url_batch("#{id}/#{name}")
    body = body
    |> Enum.map(fn({key, value}) -> "#{key}=#{value}" end)
    |> Enum.join("&amp;")
    api ++ [%{"method" => "POST", "relative_url" => relative_url, "body" => body}]
  end

  @doc """
  Use `delete_connections` to delete object from connections

  Example:

    {:ok, response} = delete_connections(:me, :feed, %{})
  """
  @spec delete_connections(id, name, params) :: success | error
  def delete_connections(id, name, params), do: _delete(id, name, params)

  @doc """
  Use `delete_connections` for deleting items from connections using batch api
  """
  @spec delete_connections(api, id, name, params) :: Map.t
  def delete_connections(api, id, name, params) do
    relative_url = _make_url_batch(params, "#{id}/#{name}")
    api ++ [%{"method" => "DELETE", "relative_url" => relative_url}]
  end


  @doc """
  Use `delete_object` to delete object from facebook data.

  Example:

    {:ok, response} = delete_connections(:me, :feed, %{})
  """
  @spec delete_object(id, params) :: success | error
  def delete_object(id, params), do: _delete(id, params)


  @doc """
  Use `delete_object` for deleting item from facebook data.
  """
  @spec delete_object(api, id, params) :: Map.t
  def delete_object(api, id, params) do
    relative_url = _make_url_batch(params, id)
    api ++ [%{"method" => "DELETE", "relative_url" => relative_url}]
  end


  @doc """
  Returns hash of image data for passed id.
  """
  @spec get_picture_data(id, params) :: success | error
  def get_picture_data(id, params) do
    params = Map.put_new(params, :redirect, false)
    _get(id, :picture, params)
  end

  @doc false
  @spec get_picture_data(api, id, params) :: Map.t
  def get_picture_data(api, id, params) do
    params = Map.put_new(params, :redirect, false)
    relative_url = _make_url_batch(params, "#{id}/picture")
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end


  @doc false
  @spec get_page_access_token(id, params) :: success | error
  def get_page_access_token(id, params) do
    params = Map.put(params, :fields, "access_token")
    _get(id, params)
  end

  @doc false
  @spec get_page_access_token(api, id, params) :: Map.t
  def get_page_access_token(api, id, params) do
    params = Map.put(params, :fields, "access_token")
    relative_url = _make_url_batch(params, id)
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end


  @doc false
  @spec put_like(id, params) :: success | error
  def put_like(id, params), do: put_connections(id, :likes, params, %{})

  @doc false
  @spec put_like(api, id, params) :: Map.t
  def put_like(api, id, params), do: put_connections(api, id, :likes, params, %{})


  @doc false
  @spec put_comment(id, params, String.t) :: success | error
  def put_comment(id, params, message) do
    put_connections(id, :comments, params, %{message: message})
  end

  @doc false
  @spec put_comment(api, id, params, String.t) :: Map.t
  def put_comment(api, id, params, message) do
    put_connections(api, id, :comments, params, %{message: message})
  end


  @doc false
  @spec delete_like(id, params) :: success | error
  def delete_like(id, params), do: delete_connections(id, :likes, params)

  @doc false
  @spec delete_like(api, id, params) :: success | error
  def delete_like(api, id, params), do: delete_connections(api, id, :likes, params)


  @doc false
  @spec put_picture(id, params, file) :: success | error
  def put_picture(id, params, {:file, file}) do
    _post(id, :photos, params, {:multipart, [{:file, file}]})
  end

  @doc false
  def put_picture(id, params, {:url, url}) do
    _post(id, :photos, params, {:multipart, [{:url, url}]})
  end

  @doc false
  def put_picture(id, params, file) do
    put_picture(id, params, {:file, file})
  end


  @doc false
  @spec put_video(id, params, file) :: success | error
  def put_video(id, params, {:file, file}) do
    _post(id, :videos, params, {:multipart, [{:file, file}]})
  end

  @doc false
  def put_video(id, params, {:url, url}) do
    _post(id, :videos, params, {:multipart, [{:file_url, url}]})
  end

  @doc false
  def put_video(id, params, file) do
    put_video(id, params, {:file, file})
  end


  @doc false
  @spec put_wall_post(id, String.t, params, Map.t) :: success | error
  def put_wall_post(id, message, params, attachment) do
    attachment = if Map.has_key?(attachment, :properties) and attachment[:properties] do
      Map.put(attachment, :properties, Poison.encode!(attachment[:properties]))
    else
      attachment
    end

    attachment = Map.put(attachment, :message, message)

    put_connections(id, :feed, params, attachment)
  end

  @doc false
  @spec put_wall_post(api, id, String.t, params, Map.t) :: Map.t
  def put_wall_post(api, id, message, params, attachment) do
    attachment = if Map.has_key?(attachment, :properties) and attachment[:properties] do
      Map.put(attachment, :properties, Poison.encode!(attachment[:properties]))
    else
      attachment
    end

    attachment = Map.put(attachment, :message, message)

    put_connections(api, id, :feed, params, attachment)
  end


  @doc false
  @spec exchange_access_token_info(access_token) :: success | error
  def exchange_access_token_info(access_token) do
    params = %{
      client_id: Config.id,
      client_secret: Config.secret,
      grant_type: "fb_exchange_token",
      fb_exchange_token: access_token
    }

    _get(:oauth, :access_token, params)
  end

  @doc false
  @spec exchange_access_token(access_token) :: success | error
  def exchange_access_token(access_token) do
    access_token
    |> exchange_access_token_info
    |> _parse_exchange_access_token
  end
  defp _parse_exchange_access_token({:ok, %{"access_token" => access_token}}), do: access_token
  defp _parse_exchange_access_token(_), do: nil


  defp _make_url_batch(params, path) do
    path = "#{Config.api_version}/#{path}"
    :hackney_url.make_url("", path, _batch_prepare(params))
  end


  defp _get(id, params), do:  id |> _make_url(params) |> _get
  defp _get(id, name, params), do: _get(~s(#{id}/#{name}), params)
  defp _get(url), do: Http.get(url)

  defp _post(id, params, body), do:  id |> _make_url(params) |> _post(body)
  defp _post(id, name, params, body), do: _post(~s(#{id}/#{name}), params, body)
  defp _post(url, body), do: Http.post(url, body)

  defp _delete(id, params), do:  id |> _make_url(params) |> _delete
  defp _delete(id, name, params), do: _delete(~s(#{id}/#{name}), params)
  defp _delete(url), do: Http.delete(url)


  defp _make_url(path, params) do
    path = "#{Config.api_version}/#{path}"
    :hackney_url.make_url("https://graph.facebook.com", path, _prepare(params))
  end


  defp _prepare(params), do: params |> _auth |> Map.to_list
  defp _batch_prepare(params) do
    params |> Map.delete(:access_token) |> Map.to_list
  end


  defp _auth(params), do: _encrypt(params, Config.id, Config.secret)


  defp _encrypt(params, _, nil), do: params
  defp _encrypt(params, id, secret) do
    case params do
      %{access_token: access_token} ->
        access_token = :crypto.hmac(:sha256, secret, access_token)
        appsecret_proof = Base.encode16(access_token, case: :lower)
        Map.put(params, :appsecret_proof, appsecret_proof)
      _ -> Map.put(params, :access_token, "#{id}|#{secret}")
    end
  end
end
