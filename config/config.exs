import Config

config :exfacebook,
  api_version: "v26.0",
  graph_url: "https://graph.facebook.com",
  graph_video_url: "https://graph-video.facebook.com"

if config_env() in [:dev, :test] do
  import_config "#{config_env()}.exs"
end
