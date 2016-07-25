defmodule ExfacebookTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Exfacebook.TestConfig

  alias Exfacebook.Params

  setup_all do
    {:ok, _} = Exfacebook.start_link(name: __MODULE__)
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  test "get_object for facebook" do
    pid = __MODULE__

    use_cassette "get_object#me_fields_id_name" do
      params = %Params{access_token: access_token, fields: "id,name"}
      {:ok, %{"id" => id, "name" => name}} = Exfacebook.get_object(pid, :me, params)
      assert id == "127016687734698"
      assert name == "Richard Alabgiajbgak Thurnman"
    end
  end

  test "get_connections for authenticated user for feed" do
    pid = __MODULE__

    use_cassette "get_connections#majesticcasual_fields_id_name" do
      params = %Params{access_token: access_token, fields: "id,name"}
      {:ok, %{"data" => collection}} = Exfacebook.get_connections(pid, "majesticcasual", :posts, params)
      assert Enum.count(collection) == 25
    end
  end

  test "next/prev for authenticated user for feed" do
    pid = __MODULE__
    params = %Params{access_token: access_token, fields: "id,name"}

    use_cassette "get_connections#majesticcasual_fields_id_name" do
      {:ok, %{"data" => [%{"id" => id1} | _] = collection1}} = response1 = Exfacebook.get_connections(pid, "majesticcasual", :posts, params)
      assert Enum.count(collection1) == 25

      use_cassette "get_connections#next_majesticcasual_fields_id_name" do
        {:ok, %{"data" => [%{"id" => id2} | _] = collection2}} = response2 = Exfacebook.next_page(pid, response1)
         assert Enum.count(collection2) == 25
         assert id1 != id2

         use_cassette "get_connections#prev_majesticcasual_fields_id_name" do
           {:ok, %{"data" => [%{"id" => id3} | _] = collection3}} = response3 = Exfacebook.prev_page(pid, response2)
           assert Enum.count(collection3) == 25
           assert id1 == id3
         end
      end
    end
  end
end
