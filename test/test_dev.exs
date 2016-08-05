defmodule Exfacebook.DevTest do
  require Logger

  alias Exfacebook.Api

  def list_subscriptions do
    params = %{fields: "id,name"}

    {:ok, collection} = Api.list_subscriptions(params)
    Logger.info "[Exfacebook] subscriptions: #{inspect(collection)}"
  end

  def gen_list_subscriptions do
    {:ok, pid} = Exfacebook.start_link

    params = %{fields: "id,name"}

    {:ok, collection} = Exfacebook.list_subscriptions(pid, params)
    Logger.info "[Exfacebook] subscriptions: #{inspect(collection)}"
  end

  def subscribe do
    {:ok, pid} = Exfacebook.start_link

    params = %{fields: "id,name"}

    {:ok, collection} = Exfacebook.list_subscriptions(pid, params)
    Logger.info "[Exfacebook] subscriptions: #{inspect(collection)}"
  end

  def gen_subscribe do

  end
end

Exfacebook.DevTest.list_subscriptions
Exfacebook.DevTest.gen_list_subscriptions
