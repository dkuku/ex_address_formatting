defmodule AddressFormatting.MixProject do
  use Mix.Project

  def project do
    [
      app: :address_formatting,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  defp description do
    "address formatting implemetation"
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README*",
        "address-formatting/conf/countries/*",
        "address-formatting/conf/abbreviations/*",
        "address-formatting/conf/*"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/dkuku/ex_address_formatting",
        "Original project homepage" => "https://github.com/OpenCageData/address-formatting/"
      }
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
      {:yaml_elixir, "~> 2.7"},
      {:benchee, "~> 1.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
