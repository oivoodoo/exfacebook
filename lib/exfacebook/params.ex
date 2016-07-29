defmodule Exfacebook.Params do
  @moduledoc ~S"""
  Facebook allowed to pass specific params in API requests

  * limit - `25` value is default
  * access_token - should be encrypted in case of using in requests for
  authenticated users
  * fields - specify fields to return in response, example: `"id, name"`
  """
  defstruct limit: 25, access_token: nil, fields: ""
end
