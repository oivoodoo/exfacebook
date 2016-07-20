defmodule Exfacebook.Config do
  def api_version do
    Application.get_env(:exfacebook, :api_version, "v2.6")
  end
end
