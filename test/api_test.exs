defmodule ApiTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Exfacebook.Api

  setup_all do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  # Lets use access_token of test user that was created for one of the
  # facebook apps via Dashboard -> Roles -> Test Users
  @access_token "EAAHHZBahuow0BADcvfiryoKrP96OCCRdnZAZBvj89qiFsRMvWqLlkqooqFbkPbZApTb2B7KjNMAgihPRZC6oP3k65nNQEI1nzRkY0dEgTuSzoNdyggc8zS3ZAjGnInB6UdlcwCIYR8v6zgAaZBObJ3UZCvN8ZAy8SkRFq5x1t4mwog3wOO07NIg1z"

  test "get_object for facebook" do
    use_cassette "get_object#me_fields_id_name" do
      params = %Api.Params{access_token: @access_token, fields: "id,name"}
      {:ok, %{"id" => id, "name" => name}} = Api.get_object(:me, params)
      assert id == "115609768877496"
      assert name == "Bob Alabhedbjacaa Carrieroman"
    end
  end

  test "get_connections for authenticated user for feed" do
    use_cassette "get_connections#me_fields_id_name" do
      params = %Api.Params{access_token: @access_token, fields: "id,name"}
      {:ok, %{"data" => collection}} = Api.get_connections("me", :feed, params)
      assert Enum.count(collection) == 0
    end
  end

  test "get_connections for feed of page" do
    # TODO: add app_id, app_secret
    # 1. -app_id, -app_secret, -access_token should response
    #    with error
    # 2. -app_id, -app_secret, +access_token should skip encrypt
    #    token
    # 3. +app_id, +app_secret, +access_token should skip encrypt and use
    #    access_token.
    # 4. +app_id, +app_secret, -access_token should encrypt app_id|app_secret
    use_cassette "get_connections#majesticcasual_fields_id_name" do
      params = %Api.Params{access_token: @access_token, fields: "id,name"}
      {:ok, %{"data" => collection}} = Api.get_connections("majesticcasual", :feed, params)
      assert Enum.count(collection) == 0
    end
  end
end
