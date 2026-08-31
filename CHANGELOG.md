# Changelog

## [0.2.0] - 2026-08-31

### Changed
- Default Graph API version is now `v26.0` (was `v2.6`, which expired in 2018).
  See https://developers.facebook.com/docs/graph-api/changelog/versions/
- Require Elixir 1.14+ and replace Poison with Jason.
- Upgrade HTTPoison to 2.x. HTTP options are now read at runtime.
- Replace `:crypto.hmac/3` (removed in OTP 24) with `:crypto.mac/4`.
- Parse Graph API error objects (`message`, `type`, `code`, `error_subcode`, `fbtrace_id`)
  instead of returning a generic "not found resource" message.
- Treat HTTP 2xx as success so create calls that return 201 work.
- Preserve batch response order (previously reversed).
- Encode batch POST bodies with `&` instead of `&amp;`.
- Send video uploads to `graph-video.facebook.com`.
- POST/DELETE GenServer methods now use `call` so callers receive the API response.
  `handle_cast` previously returned `{:reply, ...}`, which crashes a GenServer.
- Replace Dogma with Credo. Drop inch_ex.

### Added
- `Exfacebook.Api.meet_challenge/2` for Webhooks verification requests.
- `Exfacebook.Api.appsecret_proof/1`.
- Configurable `graph_url` and `graph_video_url`.

### Security
- Stop logging access tokens and app secret proofs.
- Move app credentials out of shared `config/config.exs`.
