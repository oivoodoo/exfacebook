defmodule ApiTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  require Logger

  import Exfacebook.TestConfig

  alias Exfacebook.Api

  setup_all do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  test "get_object for facebook" do
    use_cassette "get_object#me_fields_id_name" do
      params = %{access_token: access_token, fields: "id,name"}
      {:ok, %{"id" => id, "name" => name}} = Api.get_object(:me, params)
      assert id == "127016687734698"
      assert name == "Richard Alabgiajbgak Thurnman"
    end
  end

  test "get_connections for authenticated user for feed" do
    use_cassette "get_connections#me_fields_id_name" do
      params = %{access_token: access_token, fields: "id,name"}
      {:ok, %{"data" => collection}} = Api.get_connections("me", :feed, params)
      assert Enum.count(collection) == 0
    end
  end

  test "get_connections for feed of page" do
    use_cassette "get_connections#majesticcasual_fields_id_name" do
      params = %{fields: "id,name"}
      {:ok, %{"data" => collection}} = Api.get_connections("majesticcasual", :posts, params)
      assert Enum.count(collection) == 25
    end
  end

  test "next and prev page for get_connections request" do
    use_cassette "get_connections#majesticcasual_fields_id_name_next_prev" do
      response1 = Api.get_connections("majesticcasual", :posts, %{fields: "id,name", limit: 25})

      use_cassette "get_connections#majesticcasual_fields_id_name_next_page1" do
        response2 = response1 |> Api.next_page
        {:ok, %{"data" => [item1 | _]}} = response1
        {:ok, %{"data" => [item2 | _]}} = response2
        assert item1["id"] != item2["id"]

        use_cassette "get_connections#majesticcasual_fields_id_name_prev_page1" do
          response3 = response2 |> Api.prev_page
          {:ok, %{"data" => [item3 | _]}} = response3
          # Facebook API returns 24 items
          # assert item1["id"] == item3["id"]
        end
      end
    end
  end

end
