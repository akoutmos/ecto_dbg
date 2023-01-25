defmodule EctoDbg.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_dbg,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :erlexec]
    ]
  end

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
end
