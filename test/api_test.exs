defmodule ApiTest do
  use ExUnit.Case
  doctest Exfacebook.Api

  alias Exfacebook.Api, as: Facebook

  @url "https://graph.facebook.com/majesticcasual/posts?fields=id,name,picture,description,link,from,created_time,application,comments.limit(1).summary(true),to,likes.limit(1).summary(true)&access_token=199502190383212|9ae024603797bbcd31d938feba4cd033"
  test "get response with json and add one more item to sidekiq" do
    assert Facebook.id(@url) == "majesticcasual"
  end

  @access_token "access-token"
  @object_id "object-id"

  test "get_object for facebook" do
    params = %Facebook.Params{access_token: @access_token, fields: "id,name"}
    {:ok, %{"id" => id}} = Facebook.get_object(@object_id, params)
    assert id == "1264937113"
  end

  test "get_connections for facebook" do
    params = %Facebook.Params{access_token: @access_token, fields: "id,name"}
    {:ok, %{"data" => collection}} = Facebook.get_connections(@object_id, :feed, params)
    assert Enum.count(collection) == 25
  end
end
