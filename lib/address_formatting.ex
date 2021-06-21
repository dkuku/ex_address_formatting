defmodule AddressFormatting do
  @moduledoc """
  Documentation for `AddressFormatting`.
  """

  def render(template, variables) do
    :bbmustache.render(template, variables, [key_type: :binary])
  end

  def parse_yaml(path) do
    full_path = Path.join(File.cwd!(), path)
    {:ok, result} = YamlElixir.read_from_file(path)
    result
  end
end
