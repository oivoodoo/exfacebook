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

## TODO:

- [ ] batch
- [ ] realtime updates subscribe, list_subscriptions, unsubscribe, meet_challenge
- [ ] put_*
