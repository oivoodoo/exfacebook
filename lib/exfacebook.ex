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

      {:ok, pid} = Exfacebook.start_link

    * `get_object` - get user or page related attributes, in case if you decide to
    use specific params for Facebook API pass them to Params struct:

      {:ok, %{"id" => id, "picture" => picture}} = Exfacebook.get_object(pid, :me, %Params{access_token: "access-token", fields: "id, picture"})

    * `get_connections` - get collection related items and attributes(feed or home or friends):

      {:ok, %{"data" => collection}} = response = Exfacebook.get_connections(pid, :feed, %Params{fields: "id, name", access_token: "access-token"})

    * `next_page`/`prev_page` - take next or prev collections using response from `get_connections`:

      response = Exfacebook.get_connections(pid, :feed, %Params{fields: "id, name", access_token: "access-token"})
      response2 = Exfacebook.next_page(pid, response)
      response3 = Exfacebook.next_page(pid, response2)
      response4 = Exfacebook.prev_page(pid, response3)

    * `put_connections` - update actions in facebook, example creates the new message in feed:

      Exfacebook.put_connections(:me, :feed, %Params{access_token: "access-token"}, %{message: "hello"})
  """

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  define_api :get_object, :get, [id, params]
  define_api :get_connections, :get, [id, name, params]
  define_api :next_page, :get, [response]
  define_api :prev_page, :get, [response]
  define_api :put_connections, :post, [id, name, params, body]

  @doc ~S"""
  Passing prepared params for batch processing using Facebook API.

  Params are coming like normal requests encoded to JSON and then Facebook
  emulate requests on their side:
  """
  def batch(params, callback) do
    callback.([]) |> Api.batch(params)
  end
end
