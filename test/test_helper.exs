Code.require_file("test_config.exs", "test/")

ExUnit.configure formatters: [ExUnit.CLIFormatter, ExUnitNotifier]
ExUnit.start()
