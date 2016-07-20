defmodule Exfacebook.Config do
  @moduledoc false

  @doc false
  def api_version do
    Application.get_env(:exfacebook, :api_version, "v2.6")
  end

  @doc false
  def secret do
    Application.get_env(:exfacebook, :secret)
  end

  @doc false
  def id do
    Application.get_env(:exfacebook, :id)
  end
end
