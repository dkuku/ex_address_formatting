defmodule AddressFormatting.FileHelpers do
  @conf_path "address-formatting/conf"
  @test_path "address-formatting/testcases"

  def load_abbreviations(), do: load_directory(@conf_path, "abbreviations")
  def load_testcases_other(), do: load_directory(@test_path, "other")
  def load_testcases_countries(), do: load_directory(@test_path, "countries")

  def load_directory(path, directory) do
    [File.cwd!(), path, directory]
    |> Path.join()
    |> File.ls!()
    |> Enum.map(&String.split(&1, "."))
    |> Enum.map(fn [filename, _ext] ->
      country_code =
        String.split(filename, ".")
        |> hd()
        |> String.upcase()

      {country_code, load_yaml(path, directory, filename)}
    end)
    |> Map.new()
  end

  def load_yaml(name) do
    filename = Enum.join([name, "yaml"], ".")

    Path.join([File.cwd!(), @conf_path, filename])
    |> parse_yaml()
  end

  def load_yaml(directory, name) do
    filename = Enum.join([name, "yaml"], ".")

    Path.join([File.cwd!(), @conf_path, directory, filename])
    |> parse_yaml()
  end

  def load_yaml(conf_path, directory, name) do
    filename = Enum.join([name, "yaml"], ".")

    Path.join([File.cwd!(), conf_path, directory, filename])
    |> parse_yaml()
  end

  def parse_yaml(path) do
    case YamlElixir.read_from_file(path) do
      {:ok, result} -> result
    end
  end
end
