defmodule EctoDbg.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_dbg,
      version: "0.1.0",
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
      extra_applications: [:logger, :erlexec]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Required dependencies
      {:ecto_sql, "~> 3.7"},
      {:ecto_dev_logger, "~> 0.8.0"},
      {:erlexec, "~> 2.0"},

      # Development dependencies
      {:ex_doc, "~> 0.29.1", only: :dev},
      {:excoveralls, "~> 0.15.3", only: :test, runtime: false},
      {:credo, "~> 1.6.1", only: :dev},
      {:dialyxir, "~> 1.2.0", only: :dev, runtime: false},
      {:git_hooks, "~> 0.7.3", only: [:test, :dev], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "master",
      logo: "guides/images/logo.svg",
      extras: [
        "README.md"
      ]
    ]
  end

  defp package do
    [
      name: "ecto_dbg",
      files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md),
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
