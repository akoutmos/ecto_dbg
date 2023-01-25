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
      {:ecto_sql, "~> 3.7"},
      {:ecto_dev_logger, "~> 0.8.0"},
      {:erlexec, "~> 2.0"}
    ]
  end
end
