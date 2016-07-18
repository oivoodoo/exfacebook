defmodule Exfacebook.Api do
  require Poison

  alias Exfacebook.Http
  alias HTTPoison.Response
  alias HTTPoison.Error

  defmodule Params do
    defstruct limit: 25, access_token: nil, fields: ""
  end


  @doc """
  Use get_connections to read feed, home collections.
  """
  def get_connections(params, object_id, object_name) do
    _request(object_name, object_id, params)
  end


  def next_page({:error, _error} = state), do: state
  def next_page({:ok, %{"paging" => %{"next" => url}}}), do: _request(url)
  def next_page({:ok, _response}), do: {:ok, %{"data" => []}}


  def prev_page({:error, _error} = state), do: state
  def prev_page({:ok, %{"paging" => %{"previous" => url}}}), do: _request(url)
  def prev_page({:ok, _response}), do: {:ok, %{"data" => []}}


  def get_object(params, object_id) do
    _request(object_id, params)
  end


  defp _request(object_id, params) do
    url = _make_url(object_id, params)
    _request(url)
  end
  defp _request(object_name, object_id, params), do: _request(~s(#{object_id}/#{object_name}), params)
  defp _request(url), do: Http.get(url)


  def auth(%Params{access_token: access_token} = params, secret) do
    Map.put(params, :appsecret_proof, _encrypt(secret, access_token))
  end


  defp _make_url(path, %Params{access_token: _access_token} = params) do
    params = params |> Map.delete(:__struct__) |> Map.to_list
    :hackney_url.make_url("https://graph.facebook.com", "#{@api_version}/#{path}", params)
  end


  defp _encrypt(secret, token) do
    :crypto.hmac(:sha256, secret, token)
    |> Base.encode16(case: :lower)
  end
end
