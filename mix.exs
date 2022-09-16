defmodule SanitySync.MixProject do
  use Mix.Project

  def project do
    [
      app: :sanity_sync,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SanitySync.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:jason, "~> 1.4"},
      {:postgrex, ">= 0.0.0"},
      {:unsafe_atomize_keys, "~> 1.1"},

      # Dev/test
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
