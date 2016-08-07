defmodule BatchTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Exfacebook
  import Exfacebook.TestConfig

  alias Exfacebook.Error

  require Logger

  setup_all do
    {:ok, _} = Exfacebook.start_link(name: __MODULE__)
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  test "get_object for facebook using batch api" do
    use_cassette "batch#get_object" do
      pid = __MODULE__

      response = batch %{access_token: access_token}, fn(api) ->
        api = api |> get_object(pid, :me, %{fields: "id, name"})
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

      response = batch %{access_token: access_token}, fn(api) ->
        api = api |> get_object(pid, :me, %{fields: "id, name"})
        assert api == [
          %{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"}
        ]

        api = api |> get_connections(pid, :me, :feed, %{fields: "id, name"})
        assert api == [
          %{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"},
          %{"method" => "GET", "relative_url" => "/v2.6/me/feed?fields=id%2c+name"},
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

      response = batch %{access_token: access_token}, fn(api) ->
        api = api |> get_object(pid, :me, %{fields: "id, name"})
        assert api == [%{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"}]

        api = api |> get_connections(pid, "unknown-page", :posts, %{fields: "id, name"})
        assert api == [
          %{"method" => "GET", "relative_url" => "/v2.6/me?fields=id%2c+name"},
          %{"method" => "GET", "relative_url" => "/v2.6/unknown-page/posts?fields=id%2c+name"}
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

      response = Exfacebook.get_connections(pid, :me, :feed, %{access_token: access_token})

      response = batch %{access_token: access_token}, fn(api) ->
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

      response = Exfacebook.get_connections(pid, "majesticcasual", :posts, %{})

      response = batch fn(api) ->
        api = api |> next_page(pid, response)
        api = api |> prev_page(pid, response)

        # no data
        assert api == [
          %{"method" => "GET", "relative_url" => "/v2.6/221646591235273/posts?limit=25&access_token=217873215035447|4e2d3c9835e99d8dc7c93d62cc16d159&until=1468086000&__paging_token=enc_AdCYZC3qrd3imNKJzRp8vyDGk84d7CRwoBSARcokLJa5K0bvD1CCZCqXZCGRIqqo11ax0EjtjPL99C0CO1BoatlCcshaIWAhcmrZCRcNhTZADmZCZC2oQZDZD"},
          %{"method" => "GET", "relative_url" => "/v2.6/221646591235273/posts?limit=25&since=1470591600&access_token=217873215035447|4e2d3c9835e99d8dc7c93d62cc16d159&__paging_token=enc_AdBzj3BvhRyYQ4CiqFQvFrmvCz2OQV3vNMZBXZA9G3YfJmLOdK6lbcNQ8Nyage5WvxwZB8QNDgz5b4y1hZA2FWL0RZCcJjMBXDB6pvd5u43sgCYNhZBwZDZD&__previous=1"}
        ]

        api
      end

      [{:ok, %{"data" => collection1}}, {:ok, %{"data" => collection2}}] = response
      assert Enum.count(collection1) == 0   # prev
      assert Enum.count(collection2) == 25  # next
    end
  end
end
