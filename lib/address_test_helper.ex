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

  defmacro assert_render(input_tuple, render_fn) do
    quote bind_quoted: [data: input_tuple, render_fn: render_fn] do
      {file,
       %{
         "components" => components,
         "description" => description,
         "expected" => expected
       }} = data

      rendered = render_fn.(components)

      case ExUnit.Diff.compute(expected, rendered, :==) do
        {%ExUnit.Diff{equivalent?: true}, _} ->
          true

        {%ExUnit.Diff{left: {_, _, left}, right: {_, _, right}}, _} ->
          IO.puts("""
          =================================
          Test: #{file} - #{description}
          expected: #{AddressHelper.colorize_diff(left)}
          rendered: #{AddressHelper.colorize_diff(right)}
          """)

          components
          |> Enum.each(fn {a, b} -> IO.puts("#{a}: #{b}") end)
          |> IO.inspect()

          false
      end
    end
  end
end
