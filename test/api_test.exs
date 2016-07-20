defmodule ApiTest do
  use ExUnit.Case

  alias Exfacebook.Api

  setup do
    {:ok, _} = Exfacebook.start_link(name: Exfacebook)
    :ok
  end

  # Lets use access_token of test user that was created for one of the
  # facebook apps via Dashboard -> Roles -> Test Users
  @access_token "EAAHHZBahuow0BAIyZB8ZC80SC3ZAoEoFCndktXZAruzVY2ZAMzHEbSkZCFnjqqdIBFpHKDzQRIXMSAFK4HZALZBeh29xZATH5urKw2rtQglw6fFZCd47Y0ixAfcUQlbKh20p50lRI41iIvDasDDiH1KZBrVEvgqgWaSqg041DX4bZCqYd0PxnZBsiJm58F"
  @object_id "majesticcasual"

  test "get_object for facebook" do
    params = %Api.Params{access_token: @access_token, fields: "id,name"}
    {:ok, %{"id" => id}} = Api.get_object(@object_id, params)
    assert id == "1264937113"
  end

  # test "get_connections for facebook" do
  #   params = %Api.Params{access_token: @access_token, fields: "id,name"}
  #   {:ok, %{"data" => collection}} = Api.get_connections(@object_id, :feed, params)
  #   assert Enum.count(collection) == 25
  # end
end
