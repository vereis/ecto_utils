defmodule EctoUtils.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      app: :ecto_utils,
      version: "0.2.0",
      elixir: "~> 1.12",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Actual dependencies,
      {:ecto, "~> 3.6"},

      # Lint dependencies
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},

      # Test dependencies
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:etso, "~> 0.1.2", only: :test},

      # Misc dependencies
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [lint: ["format --check-formatted --dry-run", "credo --strict", "dialyzer"]]
  end

  defp description() do
    """
    Collection of various Ecto related utilities I tend to re-implement on every project I work on.
    """
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/vereis/ecto_utils"
      }
    ]
  end
end
