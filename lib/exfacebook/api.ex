defmodule Exfacebook.Api do
  @moduledoc ~S"""
  Basic functions for accessing the Facebook Graph API.
  """

  alias Exfacebook.Http
  alias Exfacebook.Config
  alias Exfacebook.Error

  @type name :: String.t()
  @type id :: String.t() | atom()
  @type success :: {:ok, map()}
  @type error :: {:error, Error.t()}
  @type api :: list()
  @type body :: map()
  @type params :: map()
  @type file :: String.t() | tuple()
  @type access_token :: String.t()

  @doc """
  Use `get_connections` to read feed, home collections.

  Example:

    {:ok, %{"data" => collection}} = get_connections(:me, :feed, %{fields: "id, name"})
  """
  @spec get_connections(id, name, params) :: success | error
  def get_connections(id, name, params) do
    params = Map.put_new(params, :limit, 25)
    get(id, name, params)
  end

  @doc """
  Use `get_connections` for getting collection using batch Facebook API.
  """
  @spec get_connections(api, id, name, params) :: api
  def get_connections(api, id, name, params) do
    relative_url = make_url_batch(params, "#{id}/#{name}")
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end

  @doc ~S"""
  Getting list of subscriptions for app, we don't need to use user access
  token, it requires to have only app_id and secret.
  """
  @spec list_subscriptions(params) :: success | error
  def list_subscriptions(params) do
    params = params |> Map.delete(:access_token)
    get(Config.id(), :subscriptions, params)
  end

  @doc ~S"""
  Subscribe to real time updates to object.

  `callback_url` - https api endpoint to receive real time updates.
  `verify_token` - token to verify post request from facebook with updates.
  `fields` - 'friends, feed' as an example.
  """
  @spec subscribe(id, String.t(), String.t(), String.t() | nil) :: success | error
  def subscribe(id, fields, callback_url, verify_token \\ nil) do
    params =
      %{
        object: id,
        callback_url: callback_url,
        fields: fields
      }
      |> assign_verify_token(verify_token)

    post_path(:subscriptions, params, {:form, []})
  end

  @doc ~S"""
  `id` - id of object to unsubscribe, in case if developer passed `nil`
  unsubscribe would apply for all subscriptions for facebook app.
  """
  @spec unsubscribe(id) :: success | error
  def unsubscribe(id) do
    params = %{object: id}
    delete(:subscriptions, params)
  end

  @doc """
  Handle a Webhooks verification request.

  Facebook sends `hub.mode`, `hub.verify_token`, and `hub.challenge`.
  Return `{:ok, challenge}` when the request is valid.

  Source: https://developers.facebook.com/docs/graph-api/webhooks/getting-started
  """
  @spec meet_challenge(map(), String.t()) :: {:ok, String.t()} | error
  def meet_challenge(params, verify_token) when is_map(params) do
    mode = param(params, ["hub.mode", :mode, "mode"])
    token = param(params, ["hub.verify_token", :verify_token, "verify_token"])
    challenge = param(params, ["hub.challenge", :challenge, "challenge"])

    if mode == "subscribe" and token == verify_token and not is_nil(challenge) do
      {:ok, to_string(challenge)}
    else
      {:error, %Error{message: "invalid verify token or hub.mode"}}
    end
  end

  defp assign_verify_token(params, nil), do: params
  defp assign_verify_token(params, token), do: Map.put(params, :verify_token, token)

  @doc """
  Pagination `next_page` is using response from calls of `get_connections`.

  Example:

      page0 = get_connections(...)
      page1 = page0 |> next_page
      page0 = page1 |> prev_page
  """
  @spec next_page(success | error) :: success | error
  def next_page({:error, _error} = state), do: state
  def next_page({:ok, %{"paging" => %{"next" => url}}}), do: get(url)
  def next_page({:ok, _response}), do: {:ok, %{"data" => []}}

  @doc false
  @spec next_page(api, success | error) :: api
  def next_page(api, {:error, _error}), do: api

  def next_page(api, {:ok, %{"paging" => %{"next" => url}}}) do
    api ++ [%{"method" => "GET", "relative_url" => relative_paging_url(url)}]
  end

  def next_page(api, {:ok, _response}), do: api

  @doc false
  @spec prev_page(success | error) :: success | error
  def prev_page({:error, _error} = state), do: state
  def prev_page({:ok, %{"paging" => %{"previous" => url}}}), do: get(url)
  def prev_page({:ok, _response}), do: {:ok, %{"data" => []}}

  @doc false
  @spec prev_page(api, success | error) :: api
  def prev_page(api, {:error, _error}), do: api

  def prev_page(api, {:ok, %{"paging" => %{"previous" => url}}}) do
    api ++ [%{"method" => "GET", "relative_url" => relative_paging_url(url)}]
  end

  def prev_page(api, {:ok, _response}), do: api

  @doc false
  def batch(data, params) do
    params = auth(params)

    payload = [
      batch: Jason.encode!(data),
      access_token: params.access_token
    ]

    Http.post(Config.graph_url(), {:form, payload}) |> handle_batch()
  end

  defp handle_batch({:error, _} = state), do: state

  defp handle_batch({:ok, responses}) when is_list(responses) do
    Enum.map(responses, &process_batch/1)
  end

  defp handle_batch({:ok, _other}) do
    {:error, %Error{message: "batch response was not a list"}}
  end

  defp process_batch(%{"body" => body, "code" => code}) when code in 200..299 do
    Http.decode_graph_response(code, body)
  end

  defp process_batch(%{"body" => body, "code" => code}) do
    Http.decode_graph_response(code, body)
  end

  defp process_batch(other) do
    {:error, %Error{message: inspect(other)}}
  end

  @doc ~S"""
  Use `get_object` for getting object related attributes

  Example:

    {:ok, %{"id" => id, "name" => name}} = get_object(:me, %{access_token: "access-token", fields: "id, name"})
  """
  @spec get_object(id, params) :: success | error
  def get_object(id, params), do: get(id, params)

  @doc """
  Use `get_object` for getting object related attributes as part of batch API.
  """
  @spec get_object(api, id, params) :: api
  def get_object(api, id, params) do
    relative_url = make_url_batch(params, id)
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
    post_edge(id, name, params, {:form, body})
  end

  @doc """
  Use `put_connections` for posting messages or other update actions.
  """
  @spec put_connections(api, id, name, params, body) :: api
  def put_connections(api, id, name, params, body) do
    relative_url = params |> make_url_batch("#{id}/#{name}")

    encoded_body =
      body
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join("&")

    api ++ [%{"method" => "POST", "relative_url" => relative_url, "body" => encoded_body}]
  end

  @doc """
  Use `delete_connections` to delete object from connections

  Example:

    {:ok, response} = delete_connections(:me, :feed, %{})
  """
  @spec delete_connections(id, name, params) :: success | error
  def delete_connections(id, name, params), do: delete(id, name, params)

  @doc """
  Use `delete_connections` for deleting items from connections using batch api
  """
  @spec delete_connections(api, id, name, params) :: api
  def delete_connections(api, id, name, params) do
    relative_url = make_url_batch(params, "#{id}/#{name}")
    api ++ [%{"method" => "DELETE", "relative_url" => relative_url}]
  end

  @doc """
  Use `delete_object` to delete object from facebook data.

  Example:

    {:ok, response} = delete_object("item-id", %{})
  """
  @spec delete_object(id, params) :: success | error
  def delete_object(id, params), do: delete(id, params)

  @doc """
  Use `delete_object` for deleting item from facebook data.
  """
  @spec delete_object(api, id, params) :: api
  def delete_object(api, id, params) do
    relative_url = make_url_batch(params, id)
    api ++ [%{"method" => "DELETE", "relative_url" => relative_url}]
  end

  @doc """
  Returns hash of image data for passed id.
  """
  @spec get_picture_data(id, params) :: success | error
  def get_picture_data(id, params) do
    params = Map.put_new(params, :redirect, false)
    get(id, :picture, params)
  end

  @doc false
  @spec get_picture_data(api, id, params) :: api
  def get_picture_data(api, id, params) do
    params = Map.put_new(params, :redirect, false)
    relative_url = make_url_batch(params, "#{id}/picture")
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end

  @doc false
  @spec get_page_access_token(id, params) :: success | error
  def get_page_access_token(id, params) do
    params = Map.put(params, :fields, "access_token")
    get(id, params)
  end

  @doc false
  @spec get_page_access_token(api, id, params) :: api
  def get_page_access_token(api, id, params) do
    params = Map.put(params, :fields, "access_token")
    relative_url = make_url_batch(params, id)
    api ++ [%{"method" => "GET", "relative_url" => relative_url}]
  end

  @doc false
  @spec put_like(id, params) :: success | error
  def put_like(id, params), do: put_connections(id, :likes, params, %{})

  @doc false
  @spec put_like(api, id, params) :: api
  def put_like(api, id, params), do: put_connections(api, id, :likes, params, %{})

  @doc false
  @spec put_comment(id, params, String.t()) :: success | error
  def put_comment(id, params, message) do
    put_connections(id, :comments, params, %{message: message})
  end

  @doc false
  @spec put_comment(api, id, params, String.t()) :: api
  def put_comment(api, id, params, message) do
    put_connections(api, id, :comments, params, %{message: message})
  end

  @doc false
  @spec delete_like(id, params) :: success | error
  def delete_like(id, params), do: delete_connections(id, :likes, params)

  @doc false
  @spec delete_like(api, id, params) :: api
  def delete_like(api, id, params), do: delete_connections(api, id, :likes, params)

  @doc false
  @spec put_picture(id, params, file) :: success | error
  def put_picture(id, params, {:file, file}) do
    post_edge(id, :photos, params, {:multipart, [{:file, file}]})
  end

  @doc false
  def put_picture(id, params, {:url, url}) do
    post_edge(id, :photos, params, {:multipart, [{:url, url}]})
  end

  @doc false
  def put_picture(id, params, file) do
    put_picture(id, params, {:file, file})
  end

  @doc false
  @spec put_video(id, params, file) :: success | error
  def put_video(id, params, {:file, file}) do
    post_edge(id, :videos, params, {:multipart, [{:file, file}]}, host: Config.graph_video_url())
  end

  @doc false
  def put_video(id, params, {:url, url}) do
    post_edge(id, :videos, params, {:multipart, [{:file_url, url}]},
      host: Config.graph_video_url()
    )
  end

  @doc false
  def put_video(id, params, file) do
    put_video(id, params, {:file, file})
  end

  @doc false
  @spec put_wall_post(id, String.t(), params, map()) :: success | error
  def put_wall_post(id, message, params, attachment) do
    attachment = encode_properties(attachment)
    attachment = Map.put(attachment, :message, message)
    put_connections(id, :feed, params, attachment)
  end

  @doc false
  @spec put_wall_post(api, id, String.t(), params, map()) :: api
  def put_wall_post(api, id, message, params, attachment) do
    attachment = encode_properties(attachment)
    attachment = Map.put(attachment, :message, message)
    put_connections(api, id, :feed, params, attachment)
  end

  defp encode_properties(attachment) do
    if Map.has_key?(attachment, :properties) and attachment[:properties] do
      Map.put(attachment, :properties, Jason.encode!(attachment[:properties]))
    else
      attachment
    end
  end

  @doc false
  @spec exchange_access_token_info(access_token) :: success | error
  def exchange_access_token_info(access_token) do
    params = %{
      client_id: Config.id(),
      client_secret: Config.secret(),
      grant_type: "fb_exchange_token",
      fb_exchange_token: access_token
    }

    get(:oauth, :access_token, params)
  end

  @doc false
  @spec exchange_access_token(access_token) :: String.t() | nil
  def exchange_access_token(access_token) do
    access_token
    |> exchange_access_token_info()
    |> parse_exchange_access_token()
  end

  defp parse_exchange_access_token({:ok, %{"access_token" => access_token}}), do: access_token
  defp parse_exchange_access_token(_), do: nil

  @doc """
  HMAC-SHA256 of the access token using the app secret.

  Source: https://developers.facebook.com/docs/graph-api/guides/secure-requests/
  """
  @spec appsecret_proof(String.t()) :: String.t() | nil
  def appsecret_proof(access_token) when is_binary(access_token) do
    case Config.secret() do
      secret when is_binary(secret) and secret != "" ->
        :hmac
        |> :crypto.mac(:sha256, secret, access_token)
        |> Base.encode16(case: :lower)

      _ ->
        nil
    end
  end

  defp make_url_batch(params, path) do
    path = "#{Config.api_version()}/#{path}"
    :hackney_url.make_url("", path, batch_prepare(params))
  end

  defp get(id, params), do: id |> make_url(params) |> Http.get()
  defp get(id, name, params), do: get(~s(#{id}/#{name}), params)
  defp get(url) when is_binary(url), do: Http.get(url)

  defp post_path(path, params, body, opts \\ []) do
    path |> make_url(params, opts) |> Http.post(body)
  end

  defp post_edge(id, name, params, body, opts \\ []) do
    post_path(~s(#{id}/#{name}), params, body, opts)
  end

  defp delete(id, params), do: id |> make_url(params) |> Http.delete()
  defp delete(id, name, params), do: delete(~s(#{id}/#{name}), params)

  defp make_url(path, params, opts \\ []) do
    host = Keyword.get(opts, :host, Config.graph_url())
    path = "#{Config.api_version()}/#{path}"
    :hackney_url.make_url(host, path, prepare(params))
  end

  defp prepare(params), do: params |> auth() |> query_list()

  defp batch_prepare(params) do
    params |> Map.delete(:access_token) |> query_list()
  end

  defp query_list(params) do
    params
    |> Map.to_list()
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
  end

  defp relative_paging_url(url) do
    url
    |> String.replace(Config.graph_url(), "")
    |> String.replace("https://graph.facebook.com", "")
  end

  defp auth(params), do: encrypt(params, Config.id(), Config.secret())

  defp encrypt(params, _, nil), do: params
  defp encrypt(params, _, ""), do: params

  defp encrypt(params, id, _secret) do
    case params do
      %{access_token: access_token} ->
        case appsecret_proof(to_string(access_token)) do
          nil -> params
          proof -> Map.put(params, :appsecret_proof, proof)
        end

      _ when not is_nil(id) ->
        Map.put(params, :access_token, "#{id}|#{Config.secret()}")

      _ ->
        params
    end
  end

  defp param(params, keys) do
    Enum.find_value(keys, fn key ->
      Map.get(params, key) || Map.get(params, to_string(key))
    end)
  end
end
