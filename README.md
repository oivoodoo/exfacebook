# Exfacebook

Elixir client for the Facebook Graph API, inspired by the Koala Ruby gem.

[Documentation](https://hexdocs.pm/exfacebook/Exfacebook.html)

Requires Elixir 1.14+ and defaults to Graph API **v26.0**.
Override the version if you need to pin an older still-supported release:

```elixir
config :exfacebook,
  api_version: "v26.0",
  graph_url: "https://graph.facebook.com",
  graph_video_url: "https://graph-video.facebook.com",
  http_options: [recv_timeout: :infinity],
  id: System.get_env("FACEBOOK_APP_ID"),
  secret: System.get_env("FACEBOOK_APP_SECRET")
```

Sources:
- https://developers.facebook.com/docs/graph-api/changelog/versions/
- https://developers.facebook.com/docs/graph-api/guides/secure-requests/

## Installation

  1. Add exfacebook to your list of dependencies in `mix.exs`:

        def deps do
          [{:exfacebook, "~> 0.2.0"}]
        end

  2. Ensure `:exfacebook` is started with your application (Mix starts it
     automatically when it is a dependency).

## Examples

```elixir
{:ok, pid} = Exfacebook.start_link()

{:ok, attributes} = Exfacebook.get_object(pid, :me, %{access_token: "access-token"})
```

```elixir
{:ok, %{"data" => collection}} =
  Exfacebook.get_connections(pid, :me, :feed, %{fields: "id,name", access_token: "access-token"})
```

```elixir
response = Exfacebook.get_connections(pid, :me, :feed, %{fields: "id,name", access_token: "access-token"})
{:ok, %{"data" => collection1}} = response2 = Exfacebook.next_page(pid, response)
{:ok, %{"data" => collection2}} = Exfacebook.prev_page(pid, response2)
```

Example of batch requests:

```elixir
[{:ok, %{"id" => id, "name" => name}}, {:ok, %{"data" => collection}}] =
  Exfacebook.batch(%{access_token: "access-token"}, fn api ->
    api
    |> Exfacebook.get_object(pid, :me, %{fields: "id,name"})
    |> Exfacebook.get_connections(pid, :me, :feed, %{fields: "id,name"})
  end)
```

Example of posting a message to a feed (Page posting requires a Page access token
and `pages_manage_posts`; user-feed publishing is restricted for most apps):

```elixir
Exfacebook.put_connections(pid, :me, :feed, %{access_token: "access-token"}, %{message: "hello"})
```

Using `Exfacebook.Api` outside of GenServer:

```elixir
{:ok, attributes} = Exfacebook.Api.get_object(:me, %{access_token: "access-token"})
```

Webhooks verification:

```elixir
{:ok, challenge} = Exfacebook.meet_challenge(params, "your-verify-token")
```

## Examples (live)

```
iex -S mix
```

```elixir
Code.require_file("example.exs", "examples/")
```

Requires `FACEBOOK_ACCESS_TOKEN`, `FACEBOOK_APP_ID`, and `FACEBOOK_APP_SECRET`.
