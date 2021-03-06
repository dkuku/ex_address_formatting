defmodule AddressFormatting.FileHelpers do
  @conf_path "address-formatting/conf"

  def load_abbreviations(), do: load_directory(@conf_path, "abbreviations")

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

      {country_code, load_yaml(filename, directory: directory, conf_path: path)}
    end)
    |> Map.new()
  end

  def load_yaml_reverse(name) do
    name
    |> load_yaml()
    |> Enum.map(fn {cc, map} ->
      {cc, Map.new(Enum.map(map, fn {k, v} -> {v, k} end))}
    end)
    |> Map.new()
  end

  def load_yaml(name, opts \\ []) do
    filename = Enum.join([name, "yaml"], ".")
    directory = Keyword.get(opts, :directory, "")
    conf_path = Keyword.get(opts, :conf_path, @conf_path)
    all = Keyword.get(opts, :all, false)

    Path.join([File.cwd!(), conf_path, directory, filename])
    |> parse_yaml(all)
  end

  def parse_yaml(path, all \\ false) do
    case all do
      false -> YamlElixir.read_from_file!(path)
      _ -> YamlElixir.read_all_from_file!(path)
    end
  end

  def load_components() do
    load_yaml("components", all: true)
    |> Enum.reduce(%{}, fn map, acc ->
      name = Map.get(map, "name")
      acc = Map.put(acc, String.to_atom(name), String.to_atom(name))

      case Map.get(map, "aliases") do
        nil ->
          acc

        aliases ->
          Enum.reduce(aliases, acc, &Map.put(&2, String.to_atom(&1), String.to_atom(name)))
      end
    end)
  end
end
