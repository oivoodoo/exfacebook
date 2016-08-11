defmodule Exfacebook do
  use GenServer
  use Exfacebook.Macros

  @moduledoc ~S"""
  Exfacebook implements Graph Api:

    * `Exfacebook.Api` - graph calls using access token to Facebook Graph API,
    depends on respnse it returns decoded to JSON values.

    * `Exfacebook.Config` - specify `api_version` and http requests for hackney.

  Configuration example(optional variables):

      config :exfacebook,
        api_version: "v2.6",
        http_options: [recv_timeout: :infinity],
        id: "your_app_id_optional",
        secret: "your_app_secret_optiona"

  How to use API?

  ## Examples:

    * `start_link` - if you want to have worker you can start Exfacebook GenServer and use `pid`
    as entry param for API methods:

    ```elixir
    {:ok, pid} = Exfacebook.start_link
    ```

    * `get_object` - get user or page related attributes, in case if you decide to
    use specific params for Facebook API like `fields`

    ```elixir
    {:ok, %{"id" => id, "picture" => picture}} = Exfacebook.get_object(
       pid, :me, %{access_token: "access-token", fields: "id, picture"})
    ```

    * `get_connections` - get collection related items and attributes(feed or home or friends):

    ```elixir
      {:ok, %{"data" => collection}} = response = Exfacebook.get_connections(
         pid, :feed, %{fields: "id, name", access_token: "access-token"})
    ```

    * `next_page`/`prev_page` - take next or prev collections using response from `get_connections`:

    ```elixir
      response = Exfacebook.get_connections(pid, :feed,
         %{fields: "id, name", access_token: "access-token"})
      response2 = Exfacebook.next_page(pid, response)
      response3 = Exfacebook.next_page(pid, response2)
      response4 = Exfacebook.prev_page(pid, response3)
    ```

    * `put_connections` - update actions in facebook, example creates the new message in feed:

    ```elixir
      Exfacebook.put_connections(:me, :feed,
         %{access_token: "access-token"}, %{message: "hello"})
    ```

  """

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  define_api :get_object, :get, [id, params]
  define_api :get_connections, :get, [id, name, params]
  define_api :next_page, :get, [response]
  define_api :prev_page, :get, [response]
  define_api :put_connections, :post, [id, name, params, body]

  @doc """
  Realtime updates using subscriptions API

  ## Examples:

    * `list_subscriptions` - returns list of subscriptions

    ```elixir
    params = %{fields: "id,name"}

    {:ok, %{
      "data" => [
        %{"active" => true,
          "callback_url" => "https://example.com/client/subscriptions",
          "fields" => ["feed", "friends", "music"],
          "object" => "user"}]
      }
    } = Exfacebook.Api.list_subscriptions(params)
    ```

    * `subscribe` - subscribe to real time updates for `object`, `fields` should
    contains object to watch for updates("feed, friends").

    ```elixir
    Exfacebook.Api.subscribe("id-1",
      "friends, feed", "http://www.example.com/facebook/updates",
      "token-123")
    ```

    * `unsubscribe` - unsubscribe `object` from real time updates.

    ```elixir
    Exfacebook.Api.unsubscribe("id-1")
    ```

  """
  define_api :list_subscriptions, :get, [params]
  define_api :subscribe, :post, [object, fields, callback_url, verify_token]
  define_api :unsubscribe, :post, [object]


  @doc ~S"""
  You can use `delete_object` and `delete_connections` passing pid or directly
  from Api module. In case of missing permissions to delete items you will
  error object as response.

  ## Examples:

    * `delete_connections` - delete item from connections
    ```elixir
    {:ok, response} = Exfacebook.Api.delete_connections(:me, :feed, %{ ... })
    ```

    * `delete_object` - delete item from Facebook data

    ```elixir
    {:ok, response} = Exfacebook.Api.delete_object("item-id")
    ```
  """
  define_api :delete_object, :delete, [id, params]
  define_api :delete_connections, :delete, [id, name, params]


  @doc ~S"""
  Passing prepared params for batch processing using Facebook API.

  Params are coming like normal requests encoded to JSON and then Facebook
  emulate requests on their side:
  """
  def batch(params, callback) do
    callback.([]) |> Api.batch(params)
  end
  def batch(callback), do: batch(%{}, callback)
end
