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
  """

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  define_api :get_object, :get, [id, params]
  define_api :get_connections, :get, [id, name, params]

  # def get_object(pid, id, params), do: GenServer.call(pid, {:get_object, id, params})
  # def get_connections(pid, id, name, params), do: GenServer.call(pid, {:get_connections, id, name, params})
  # def next_page(pid, response), do: GenServer.call(pid, {:next_page, response})
  # def prev_page(pid, response), do: GenServer.call(pid, {:prev_page, response})
  #
  # def get_object(collector, pid, id, params), do: GenServer.call(pid, {:get_object, id, params})
  # def get_connections(collector, pid, id, name, params), do: GenServer.call(pid, {:get_connections, id, name, params})
  # def next_page(collector, pid, response), do: GenServer.call(pid, {:next_page, response})
  # def prev_page(collector, pid, response), do: GenServer.call(pid, {:prev_page, response})

  @doc ~S"""
  Passing prepared params for batch processing using Facebook API.

  Params are coming like normal requests encoded to JSON and then Facebook
  emulate requests on their side:

  ## Example:

      [
        {
          "headers" => { "Content-Type" => "application/json" },
          "body" => { ... }
        }
      ]
  """
  def batch(params, callback) do
    callback.([]) |> Api.batch(params)
  end
end
