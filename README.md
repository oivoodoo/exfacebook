# exfacebok

Inspired by koala gem in Ruby

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exfacebook to your list of dependencies in `mix.exs`:

        def deps do
          [{:exfacebook, "~> 0.0.4"}]
        end

  2. Ensure exfacebook is started before your application:

        def application do
          [applications: [:exfacebook]]
        end


## Examples


```elixir
  {:ok, pid} = Exfacebook.start_link

  {:ok, attributes} = Exfacebook.get_object(pid, :me, %{access_token: "access-token"})
```

```elixir
  {:ok, %{"data" => collection}} = response = Exfacebook.get_connections(pid, :feed, %{fields: "id, name", access_token: "access-token"})
```

```elixir
  response = Exfacebook.get_connections(pid, :feed, %{fields: "id, name", access_token: "access-token"})
  {:ok, %{"data" => collection1}} = response2 = Exfacebook.next_page(pid, response)
  {:ok, %{"data" => collection2}} = Exfacebook.prev_page(pid, response2)
```

Example of batch requests:

```elixir
  [{:ok, %{"data" => collection}}, {:ok, %{"id" => id, "name" => name}}] = Exfacebook.batch(%{access_token: "access-token"}, fn(api) ->
    api = api |> Exfacebook.get_object(pid, :me, %{fields: "id, name"})
    api = api |> Exfacebook.get_connections(pid, :feed, %{fields: "id, name"})
    api
  end)
```

Example of posting message to feed:

``` elixir
  Exfacebook.put_connections(:me, :feed, %{access_token: "access-token"}, %{message: "hello"})
```

Using `Exfacebook.Api` outside of GenServer. `Exfacebook` module is working as
proxy for accessing Api module by specifying `GET` requests as `call` and `PUT`
as `cast` actions.

```elixir
    {:ok, attributes} = Exfacebook.Api.get_object(:me, %{access_token: "access-token"})
```

## TODO:

- [+] add test for get_connections
- [+] add test for next_page
- [+] add test for prev_page
- [+] batch api for get_object and get_connections
- [+] batch api for put_*
- [+] put_*
- [+] wrap api by GenServer for put operations as cast and get as call
- [ ] realtime updates subscribe, list_subscriptions, unsubscribe, meet_challenge
