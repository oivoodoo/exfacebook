defmodule Exfacebook.ErrorTest do
  use ExUnit.Case, async: true

  alias Exfacebook.Error
  alias Exfacebook.Http

  test "from_graph copies Facebook error fields" do
    error =
      Error.from_graph(400, %{
        "message" => "Invalid OAuth access token.",
        "type" => "OAuthException",
        "code" => 190,
        "error_subcode" => 463,
        "fbtrace_id" => "abc"
      })

    assert error.status_code == 400
    assert error.message == "Invalid OAuth access token."
    assert error.type == "OAuthException"
    assert error.code == 190
    assert error.error_subcode == 463
    assert error.fbtrace_id == "abc"
  end

  test "decode_graph_response treats Graph error objects as errors even on HTTP 200" do
    body =
      Jason.encode!(%{
        "error" => %{
          "message" => "An unexpected error has occurred.",
          "type" => "OAuthException",
          "code" => 2
        }
      })

    assert {:error, %Error{code: 2, message: "An unexpected error has occurred."}} =
             Http.decode_graph_response(200, body)
  end

  test "decode_graph_response accepts HTTP 201 JSON bodies" do
    body = Jason.encode!(%{"id" => "123"})
    assert {:ok, %{"id" => "123"}} = Http.decode_graph_response(201, body)
  end

  test "decode_graph_response keeps non-JSON error bodies" do
    assert {:error, %Error{status_code: 500, message: "oops"}} =
             Http.decode_graph_response(500, "oops")
  end
end
