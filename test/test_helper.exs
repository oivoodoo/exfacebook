Code.require_file("test_config.exs", "test/")

Logger.configure(level: :warning)

formatters =
  [ExUnit.CLIFormatter] ++
    if Code.ensure_loaded?(ExUnitNotifier), do: [ExUnitNotifier], else: []

ExUnit.configure(formatters: formatters)

ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
ExVCR.Config.strict_mode(true)

ExUnit.start()
