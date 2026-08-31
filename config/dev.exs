import Config

config :mix_test_watch,
  tasks: ~w(test),
  clear: true

config :exfacebook,
  id: System.get_env("FACEBOOK_APP_ID"),
  secret: System.get_env("FACEBOOK_APP_SECRET")
