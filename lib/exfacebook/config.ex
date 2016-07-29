defmodule Exfacebook.Config do
  @doc """
  Use supportable Facebook API versions
  """
  def api_version do
    Application.get_env(:exfacebook, :api_version, "v2.6")
  end

  @doc """
  Facebook app secret should be used in case of making app related requests
  """
  def secret do
    Application.get_env(:exfacebook, :secret)
  end

  @doc """
  Facebook app id should be used in case of signing requests using `appsecret_proof`
  when we are passing `access_token` of authenticated user.
  """
  def id do
    Application.get_env(:exfacebook, :id)
  end
end
