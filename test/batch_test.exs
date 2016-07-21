defmodule BatchTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Exfacebook.Params

  setup_all do
    {:ok, _} = Exfacebook.start_link(name: __MODULE__)
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  @access_token "EAADGJ4ZBWmDcBALXxlygc6GoIubjuCsNlLZAd6tPGpYsIppJ1TINhgwlg6bfGDyQWK7p0bZA1L12Wx41iEoApQheGPms8eIm1rT4w6htIcEzcl2aaF8Dh4G7hu3jJPE9iQJYrwAk71ZBcJ027QmJeXwDbTNNklQjZAkjgoTZBJOOajh5o9Wsmi"

  import Exfacebook

  test "get_object for facebook" do
    use_cassette "batch#get_object_and_get_connections" do
      pid = __MODULE__

      response = batch(pid, fn(api) ->
        get_object(api, :me, %Params{fields: "id, name"})
        get_connections(api, "majesticcasual", :posts, %Params{fields: "id, name"})
      end)

      [{:ok, %{"id" => id, "name" => name}}, {:ok, %{"data" => collection}}] = response
      assert id == "127016687734698"
      assert name == "Richard Alabgiajbgak Thurnman"
      assert Enum.count(collection) == 25
    end
  end
end
