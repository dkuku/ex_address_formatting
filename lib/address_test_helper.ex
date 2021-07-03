defmodule AddressHelper do
  @filename "README.md"
  @env_var "README"

  def str_or_tuple(str) when is_binary(str), do: str

  def str_or_tuple({_, _, str}) do
    IO.ANSI.format([:red, str])
  end

  def colorize_diff(list) do
    list
    |> Enum.map(&str_or_tuple/1)
    |> Enum.join()
    end

  def log_to_readme(data) do
    case System.get_env(@env_var) do
      nil -> data
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

      {template, variables} = data = AddressFormatting.get_template(components)
      rendered = AddressFormatting.render(data)
      

      case ExUnit.Diff.compute(expected, rendered, :==) do
        {%ExUnit.Diff{equivalent?: true}, _} ->
          true

        {%ExUnit.Diff{left: {_, _, left}, right: {_, _, right}}, _} ->
          IO.puts("""
          =================================
          Test: #{file} - #{description}
          expected: #{AddressHelper.colorize_diff(left)}
          rendered: #{AddressHelper.colorize_diff(right)}
          #{template}
          """)

          components
          |> Enum.each(fn {a, b} -> IO.puts("#{a}: #{b}") end)

          IO.puts("---")
          variables
          |> Map.delete("postformat_replace")
          |> Enum.each(fn {a, b} -> IO.puts("#{a}: #{b}") end)

          false
      end
    end
  end
end
