defmodule BatchTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Exfacebook
  import Exfacebook.TestConfig

  alias Exfacebook.Error
  alias Exfacebook.Params

  require Logger

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

  test "get_connections with next_page/prev_page" do
    use_cassette "batch#next_prev_get_connections" do
      pid = __MODULE__

      response = Exfacebook.get_connections(pid, :me, :feed, %Params{access_token: access_token})

      response = batch %Params{access_token: access_token}, fn(api) ->
        Logger.info "RESPONSE: #{inspect(response)}"

        api = api |> next_page(pid, response)
        api = api |> prev_page(pid, response)

        # no data
        assert api == []
        api
      end

      [] = response
    end
  end

  test "get_connections with next_page/prev_page for pages" do
    use_cassette "batch#next_prev_get_connections_for_pages" do
      pid = __MODULE__

      response = Exfacebook.get_connections(pid, "majesticcasual", :posts, %Params{})

      response = batch %Params{}, fn(api) ->
        api = api |> next_page(pid, response)
        api = api |> prev_page(pid, response)

        # no data
        assert api == [
          %{"method" => "GET", "relative_url" => "/v2.6/221646591235273/posts?limit=25&access_token=217873215035447|4e2d3c9835e99d8dc7c93d62cc16d159&until=1467141001&__paging_token=enc_AdBCRMRZCfQ3qtzKzq27JPF3qBmnFTOlGPeSAGhiRBPU7ZCcu1dQ45AIlTjolPwUGZBzs75O2V95ZAM0XaPJ2OLZC99ogNi2kX3PBuSSMRHGZCNiJFNgZDZD"},
          %{"method" => "GET", "relative_url" => "/v2.6/221646591235273/posts?limit=25&since=1469471771&access_token=217873215035447|4e2d3c9835e99d8dc7c93d62cc16d159&__paging_token=enc_AdCFYOXMeeDoDCOBfy7Nt5dVsX8LddxDzP9JuwDErCENQXMJrlZAWACd4mlDHlkhN7E4UgnhJj0gk3lx7S4YViiEzV4UcZBOEgtQl4E6ZCSe3EH7AZDZD&__previous=1"}
        ]

        api
      end

      [{:ok, %{"data" => collection1}}, {:ok, %{"data" => collection2}}] = response
      assert Enum.count(collection1) == 0   # prev
      assert Enum.count(collection2) == 25  # next
    end
  end
end
