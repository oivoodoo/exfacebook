defmodule Exfacebook.ConfigTest do
  use ExUnit.Case

  alias Exfacebook.Config

  test "config reader" do
    assert Config.api_version == "v2.6"
  end
end
