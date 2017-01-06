defmodule Exfacebook.Mixfile do
  use Mix.Project

  @version "0.0.10"

  def project do
    [app: :exfacebook,
     version: @version,
     elixir: "~> 1.2",
     description: description,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [
       vcr: :test, "vcr.delete": :test, "vcr.check": :test, "vcr.show": :test
     ],
     deps: deps,
     docs: [source_ref: "v#{@version}", main: "Exfacebook",
            canonical: "http://hexdocs.pm/exfacebook",
            source_url: "https://github.com/oivoodoo/exfacebook"]]
  end

  defp description do
    """
    Facebook API
    """
  end

  defp package do
    [maintainers: ["Alexandr Korsak"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/oivoodoo/exfacebook"},
     files: ~w(mix.exs README.md lib) ++
            ~w(test)]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [
      :logger,
      :httpoison,
      :poison
    ]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.8.1"},
      {:poison, "~> 1.5 or ~> 2.0 or ~> 3.0"},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:dogma, "~> 0.1", only: [:dev, :test]},
      {:ex_unit_notifier, "~> 0.1", only: :test},
      {:exvcr, "~> 0.7", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:inch_ex, "~> 0.5", only: :dev}
    ]
  end
end
