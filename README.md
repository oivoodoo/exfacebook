# exfacebok

Inspired by koala gem in Ruby

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exfacebook to your list of dependencies in `mix.exs`:

        def deps do
          [{:exfacebook, "~> 0.0.1"}]
        end

  2. Ensure exfacebook is started before your application:

        def application do
          [applications: [:exfacebook]]
        end


## Examples


```
    alias %Exfacebook.Params

    {:ok, pid} = Exfacebook.start_link

    {:ok, attributes} = Exfacebook.get_object(pid, :me, %Params{access_token: "access-token"})

    {:ok, %{"data" => collection}} = Exfacebook.get_connections(pid, :feed, %Params{fields: "id, name", access_token: "access-token"})

    [{:ok, %{"data" => collection}}, {:ok, %{"id" => id, "name" => name}}] = Exfacebook.batch(%Params{access_token: "access-token"}, fn(api) ->
      api = api |> Exfacebook.get_object(pid, :me, %Params{fields: "id, name"})
      api = api |> Exfacebook.get_connections(pid, :feed, %Params{fields: "id, name"})
      api
    end)

```

## TODO:

- [+] add test for get_connections
- [+] add test for next_page
- [+] add test for prev_page
- [+] batch api for get_object and get_connections
- [ ] batch api for put_*
- [ ] realtime updates subscribe, list_subscriptions, unsubscribe, meet_challenge
- [ ] put_*
- [ ] wrap api by GenServer for put operations as cast and get as call
