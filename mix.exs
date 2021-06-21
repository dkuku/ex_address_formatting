defmodule AddressFormatting.MixProject do
  use Mix.Project

  def project do
    [
      app: :address_formatting,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:bbmustache, "~> 1.12"},
      {:yaml_elixir, "~> 2.7"}
    ]
  end
end
