defmodule Exfacebook do
  use GenServer

  @moduledoc ~S"""
  Exfacebook implements:

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

  alias Exfacebook.Api

  def handle_call({:get_object, id, params}, _from, state) do
    {:reply, Api.get_object(id, params), state}
  end
end
