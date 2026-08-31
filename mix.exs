defmodule Exfacebook.Mixfile do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/oivoodoo/exfacebook"

  def project do
    [
      app: :exfacebook,
      version: @version,
      elixir: "~> 1.14",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ],
      deps: deps(),
      docs: [
        source_ref: "v#{@version}",
        main: "Exfacebook",
        canonical: "https://hexdocs.pm/exfacebook",
        source_url: @source_url
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp description do
    "Elixir client for the Facebook Graph API."
  end

  defp package do
    [
      maintainers: ["Alexandr Korsak"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib)
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:mix_test_watch, "~> 1.3.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_unit_notifier, "~> 1.3", only: :test},
      {:exvcr, "~> 0.15", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
