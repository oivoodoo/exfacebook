defmodule Exfacebook.Config do
  def api_version do
    Application.get_env(:exfacebook, :api_version)
  end
end
