import Config

# Dummy credentials used only so VCR cassettes can replay recorded HMAC signatures.
# Override with FACEBOOK_APP_ID / FACEBOOK_APP_SECRET when recording new cassettes.
config :exfacebook,
  id: System.get_env("FACEBOOK_APP_ID", "217873215035447"),
  secret: System.get_env("FACEBOOK_APP_SECRET", "4e2d3c9835e99d8dc7c93d62cc16d159"),
  http_options: [recv_timeout: 2_000, timeout: 2_000, hackney: [timeout: 2_000, pool: false]]
