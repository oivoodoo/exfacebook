defmodule Exfacebook do
  use GenServer

  @moduledoc ~S"""
  Exfacebook implements:

    * `Exfacebook.Api` - graph calls using access token to Facebook Graph API,
    depends on respnse it returns decoded to JSON values.

    * `Exfacebook.Config` - specify `api_version` and http requests for hackney.

  Configuration example:

      config :exfacebook,
        api_version: "v2.6",
        http_options: [recv_timeout: :infinity]
  """

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end
end
