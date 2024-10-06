defmodule EctoDbg.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_dbg,
      version: "0.3.0",
      elixir: "~> 1.12",
      name: "EctoDbg",
      source_url: "https://github.com/akoutmos/ecto_dbg",
      homepage_url: "https://hex.pm/packages/ecto_dbg",
      description: "Log your Ecto queries as pretty printed SQL",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      dialyzer: [
        plt_add_apps: [:ecto, :mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Required dependencies
      {:ecto_sql, "~> 3.7"},
      {:ecto_dev_logger, "~> 0.13"},
      {:sql_fmt, "~> 0.1.0"},

      # Development dependencies
      {:doctor, "~> 0.21", only: :dev},
      {:ex_doc, "~> 0.34", only: :dev},
      {:credo, "~> 1.7", only: :dev},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},

      # Test dependencies
      {:ecto_sqlite3, "~> 0.17", only: :test},
      {:excoveralls, "~> 0.18", only: :test, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "master",
      logo: "guides/images/logo.png",
      extras: [
        "README.md"
      ]
    ]
  end

  defp package do
    [
      name: "ecto_dbg",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/ecto_dbg",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_files/1]
    ]
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)
  end
end
