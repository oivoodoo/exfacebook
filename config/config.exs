use Mix.Config

config :exfacebook,
  api_version: "v2.6"

if Mix.env == :dev do
  config :mix_test_watch, tasks: ~w(test dogma), clear: true

  config :exfacebook,
    id: System.get_env("FACEBOOK_APP_ID"),
    secret: System.get_env("FACEBOOK_APP_SECRET")
end

if Mix.env == :test do
  config :exfacebook,
    id: "217873215035447",
    secret: "4e2d3c9835e99d8dc7c93d62cc16d159"
end
