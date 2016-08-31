defmodule Exfacebook.Macros do
  defmacro __using__(_) do
    quote do
      alias Exfacebook.Http
      alias Exfacebook.Api

      import Exfacebook.Macros
    end
  end

  defp _define_api(:get, function_name, arguments, [batch: is_batchable]) do
    quote do
      def unquote(:"#{function_name}")(pid, unquote_splicing(arguments)) do
        GenServer.call(pid, {unquote(function_name), unquote_splicing(arguments)})
      end

      def handle_call({unquote(:"#{function_name}"), unquote_splicing(arguments)}, _from, state) do
        {:reply,
         apply(Exfacebook.Api, unquote(function_name), [unquote_splicing(arguments)]),
         state}
      end

      if unquote(is_batchable) do
        def unquote(:"#{function_name}")(api, pid, unquote_splicing(arguments)) do
          GenServer.call(pid, {unquote(function_name), api, unquote_splicing(arguments)})
        end

        def handle_call({unquote(:"#{function_name}"), api, unquote_splicing(arguments)}, _from, state) do
          {:reply,
           apply(Exfacebook.Api, unquote(function_name), [api, unquote_splicing(arguments)]),
           state}
        end
      end
    end
  end

  defp _define_api(:post, function_name, arguments, options) do
    _define_api_resource(function_name, arguments, options)
  end

  defp _define_api(:delete, function_name, arguments, options) do
    _define_api_resource(function_name, arguments, options)
  end

  defp _define_api_resource(function_name, arguments, [batch: is_batchable]) do
    quote do
      def unquote(:"#{function_name}")(pid, unquote_splicing(arguments)) do
        GenServer.cast(pid, {unquote(function_name), unquote_splicing(arguments)})
      end

      require Logger

      def handle_cast({unquote(:"#{function_name}"), unquote_splicing(arguments)}, state) do
        {:reply,
         apply(Exfacebook.Api, unquote(function_name), [unquote_splicing(arguments)]),
         state}
      end

      if unquote(is_batchable) do
        def unquote(:"#{function_name}")(api, pid, unquote_splicing(arguments)) do
          GenServer.cast(pid, {unquote(function_name), api, unquote_splicing(arguments)})
        end

        def handle_cast({unquote(:"#{function_name}"), api, unquote_splicing(arguments)}, state) do
          {:reply,
           apply(Exfacebook.Api, unquote(function_name), [api, unquote_splicing(arguments)]),
           state}
        end
      end
    end
  end

  @doc ~S"""
  Define API method as proxy to Api module, we should have 2 types of possible
  usage for API methods.

  - single request like `Api.get_object(...)`
  - batch request:

      response = batch(params, fn(api) ->
        api = api |> Api.get_object(...)
        api = api |> Api.get_connections(...)
        api
      end)

  Response will contain 2 responses on using `get_object`, `get_connections`.
  """
  defmacro define_api(function_name, method, arguments, options \\ [batch: true]) do
    _define_api(method, function_name, arguments, options)
  end
end
