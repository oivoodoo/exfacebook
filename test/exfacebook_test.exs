defmodule ExfacebookTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Exfacebook.Params

  setup_all do
    {:ok, _} = Exfacebook.start_link(name: __MODULE__)
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  @access_token "EAADGJ4ZBWmDcBALXxlygc6GoIubjuCsNlLZAd6tPGpYsIppJ1TINhgwlg6bfGDyQWK7p0bZA1L12Wx41iEoApQheGPms8eIm1rT4w6htIcEzcl2aaF8Dh4G7hu3jJPE9iQJYrwAk71ZBcJ027QmJeXwDbTNNklQjZAkjgoTZBJOOajh5o9Wsmi"

  test "get_object for facebook" do
    use_cassette "get_object#me_fields_id_name" do
      params = %Params{access_token: @access_token, fields: "id,name"}
      {:ok, %{"id" => id, "name" => name}} = Exfacebook.get_object(__MODULE__, :me, params)
      assert id == "127016687734698"
      assert name == "Richard Alabgiajbgak Thurnman"
    end
  end

  test "get_connections for authenticated user for feed" do
    use_cassette "get_connections#majesticcasual_fields_id_name" do
      params = %Params{access_token: @access_token, fields: "id,name"}
      {:ok, %{"data" => collection}} = Exfacebook.get_connections(__MODULE__, "majesticcasual", :posts, params)
      assert Enum.count(collection) == 25
    end
  end
end