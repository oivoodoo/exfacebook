defmodule PutConnectionsTest do
  require Logger

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney


  setup_all do
    {:ok, _} = Exfacebook.start_link(name: __MODULE__)
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  # @notes
  #
  # Facebook API is not providing test users permissions and put actions.
  #
  # alias Exfacebook.Params
  #
  # import Exfacebook.TestConfig
  #
  # test "put_connections for facebook" do
  #   pid = __MODULE__
  #   params = %Params{access_token: access_token, fields: "id,name"}
  #
  #   use_cassette "put_connections#feed_me" do
  #     response = Exfacebook.put_connections(pid, :me, :feed, params, %{message: "good news!"})
  #
  #     :timer.sleep(2000)
  #
  #     use_cassette "put_connections#get_connections_feed_me" do
  #       {:ok, %{"data" => [feed | _] = collection}} = Exfacebook.get_connections(pid, :me, :feed, params)
  #       assert Enum.count(collection) == 1
  #       assert feed["message"] == "good news!"
  #     end
  #   end
  # end
end
