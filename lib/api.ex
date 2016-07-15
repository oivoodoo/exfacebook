defmodule Exfacebook.Api do
  require Poison

  alias Exfacebook.Http
  alias HTTPoison.Response
  alias HTTPoison.Error

  defmodule Params do
    defstruct limit: 25, access_token: nil, fields: "", appsecret_proof: nil
  end

  def get_connections(object_id, object_name, params) do
    _request(object_name, object_id, params)
  end

  def get_object(object_id, params) do
    _request(object_id, params)
  end

  defp _request(object_id, params) do
    _make_url(object_id, params)
    |> _request
  end
  defp _request(object_name, object_id, params), do: _request(~s(#{object_id}/#{object_name}), params)

  defp _request(url), do: Http.get(url)

  defp _make_url(path, %Params{access_token: access_token} = params) do
    params = params
    |> Map.put(:appsecret_proof, _encrypt(access_token))
    |> Map.delete(:__struct__)
    |> Map.to_list
    :hackney_url.make_url("https://graph.facebook.com", "#{@api_version}/#{path}", params)
  end

  defp _encrypt(token) do
    :crypto.hmac(:sha256, @app_secret, token)
    |> Base.encode16(case: :lower)
  end
end
