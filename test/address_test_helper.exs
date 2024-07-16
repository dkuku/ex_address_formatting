defmodule AddressTestHelper do
  @filename "README.md"
  @env_var "README"
  @test_path "address-formatting/testcases"

  def load_testcases_other() do
    AddressFormatting.FileHelpers.load_directory(@test_path, "other")
  end

  def load_testcases_countries() do
    AddressFormatting.FileHelpers.load_directory(@test_path, "countries")
  end

  def str_or_tuple({true, str}), do: str
  def str_or_tuple({false, str}), do: IO.ANSI.format([:red, str])

  def colorize_diff(list) do
    list
    |> Enum.map_join(&str_or_tuple/1)
  end

  def log_to_readme(data) do
    case System.get_env(@env_var) do
      nil ->
        data

      _ ->
        File.open(@filename, [:append])
        |> elem(1)
        |> IO.binwrite(data)

        data
    end
  end

  defmacro assert_render(input_tuple) do
    quote bind_quoted: [data: input_tuple] do
      {file,
       %{
         "components" => components,
         "description" => description,
         "expected" => expected
       }} = data

      {template, variables, _} = data = AddressFormatting.get_template(components)
      rendered = AddressFormatting.render(data)

      case ExUnit.Diff.compute(expected, rendered, :==) do
        {%ExUnit.Diff{equivalent?: true}, _} ->
          true

        {%ExUnit.Diff{left: %{contents: left}, right: %{contents: right}}, _} ->
          IO.puts("""
          =================================
          Test: #{file} - #{description}
          expected: #{AddressHelper.colorize_diff(left)}
          rendered: #{AddressHelper.colorize_diff(right)}
          """)

          components
          |> Enum.each(fn {a, b} -> IO.puts("#{a}: #{b}") end)

          IO.puts("---")
          IO.puts(variables)

          false
      end
    end
  end
end
