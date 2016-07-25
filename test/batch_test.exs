defmodule BatchTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Exfacebook
  import Exfacebook.TestConfig

  alias Exfacebook.Error
  alias Exfacebook.Params

  setup_all do
    {:ok, _} = Exfacebook.start_link(name: __MODULE__)
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  test "get_object for facebook using batch api" do
    use_cassette "batch#get_object" do
      pid = __MODULE__

      response = batch %Params{access_token: access_token}, fn(api) ->
        api = api |> get_object(pid, :me, %Params{fields: "id, name"})
        api
      end

      [{:ok, %{"id" => id, "name" => name}}] = response
      assert id == "127016687734698"
      assert name == "Richard Alabgiajbgak Thurnman"
    end
  end

  test "get_object and get_connections for facebook using batch api" do
    use_cassette "batch#get_object_and_get_connections" do
      pid = __MODULE__

      response = batch %Params{access_token: access_token}, fn(api) ->
        api = api |> get_object(pid, :me, %Params{fields: "id, name"})
        assert api == [%{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"}]

        api = api |> get_connections(pid, :me, :feed, %Params{fields: "id, name"})
        assert api == [
          %{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"},
          %{"method" => "GET", "relative_url" => "/v2.6/me/feed?fields=id%2c+name&limit=25"},
        ]
        api
      end

      [{:ok, %{"data" => collection}}, {:ok, %{"id" => id, "name" => name}}] = response
      assert id == "127016687734698"
      assert name == "Richard Alabgiajbgak Thurnman"
      assert Enum.count(collection) == 0
    end
  end

  test "get_object and get_connections with error inside for facebook using batch api" do
    use_cassette "batch#get_object_and_get_connections_and_error" do
      pid = __MODULE__

      response = batch %Params{access_token: access_token}, fn(api) ->
        api = api |> get_object(pid, :me, %Params{fields: "id, name"})
        assert api == [%{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"}]

        api = api |> get_connections(pid, "unknown-page", :posts, %Params{fields: "id, name"})
        assert api == [
          %{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"},
          %{"method" => "GET", "relative_url" => "/v2.6/unknown-page/posts?fields=id%2c+name&limit=25"},
        ]
        api
      end

      [{:error, error}, {:ok, %{"id" => id, "name" => name}}] = response
      assert id == "127016687734698"
      assert name == "Richard Alabgiajbgak Thurnman"

      %Error{message: message, status_code: status_code} = error
      assert message != nil
      assert status_code == 404
    end
  end
end
