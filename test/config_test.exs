defmodule Exfacebook.ConfigTest do
  use ExUnit.Case

  alias Exfacebook.Config

  test "config reader" do
    assert Config.api_version() == "v26.0"
    assert Config.graph_url() == "https://graph.facebook.com"
    assert Config.graph_video_url() == "https://graph-video.facebook.com"
  end
end
