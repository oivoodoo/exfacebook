defmodule Exfacebook.ApiUnitTest do
  use ExUnit.Case, async: true

  alias Exfacebook.Api
  alias Exfacebook.Error

  test "appsecret_proof is HMAC-SHA256 of the access token" do
    token = "user-access-token"
    secret = Application.get_env(:exfacebook, :secret)

    expected =
      :hmac
      |> :crypto.mac(:sha256, secret, token)
      |> Base.encode16(case: :lower)

    assert Api.appsecret_proof(token) == expected
  end

  test "meet_challenge returns the hub challenge when the verify token matches" do
    params = %{
      "hub.mode" => "subscribe",
      "hub.verify_token" => "token-123",
      "hub.challenge" => "1158201444"
    }

    assert {:ok, "1158201444"} = Api.meet_challenge(params, "token-123")
  end

  test "meet_challenge rejects a mismatched verify token" do
    params = %{
      "hub.mode" => "subscribe",
      "hub.verify_token" => "wrong",
      "hub.challenge" => "1158201444"
    }

    assert {:error, %Error{}} = Api.meet_challenge(params, "token-123")
  end

  test "batch get_object relative URLs use the configured API version" do
    api = Api.get_object([], :me, %{fields: "id, name"})
    version = Exfacebook.Config.api_version()

    assert [
             %{"method" => "GET", "relative_url" => relative_url}
           ] = api

    assert String.starts_with?(relative_url, "/#{version}/me")
  end

  test "put_connections batch body uses & not HTML entities" do
    api =
      Api.put_connections([], :me, :feed, %{fields: "id"}, %{
        message: "hello",
        link: "https://fb.com"
      })

    assert [%{"method" => "POST", "body" => body}] = api
    assert body == "message=hello&link=https://fb.com"
    refute String.contains?(body, "&amp;")
  end
end
