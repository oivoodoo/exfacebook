defmodule Exfacebook.Error do
  @moduledoc """
  Graph API error.

  Facebook error payloads look like:

      %{
        "message" => "...",
        "type" => "OAuthException",
        "code" => 190,
        "error_subcode" => 460,
        "fbtrace_id" => "..."
      }

  Source: https://developers.facebook.com/docs/graph-api/guides/error-handling
  """

  @enforce_keys [:message]
  defstruct status_code: nil,
            message: nil,
            type: nil,
            code: nil,
            error_subcode: nil,
            fbtrace_id: nil

  @type t :: %__MODULE__{
          status_code: integer() | nil,
          message: String.t(),
          type: String.t() | nil,
          code: integer() | nil,
          error_subcode: integer() | nil,
          fbtrace_id: String.t() | nil
        }

  @doc """
  Build an error from a Graph API `"error"` object.
  """
  @spec from_graph(integer() | nil, map(), String.t() | nil) :: t()
  def from_graph(status_code, error, raw \\ nil) when is_map(error) do
    %__MODULE__{
      status_code: status_code,
      message: error["message"] || raw || "Graph API error",
      type: error["type"],
      code: error["code"],
      error_subcode: error["error_subcode"],
      fbtrace_id: error["fbtrace_id"]
    }
  end
end
