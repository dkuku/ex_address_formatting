defmodule TestHelper do
  defmacro assert_render(input_tuple, render_fn) do
    quote bind_quoted: [data: input_tuple, render_fn: render_fn] do
      {file,
       %{
         "components" => components,
         "description" => description,
         "expected" => expected
       }} = data

      rendered = render_fn.(components)
      import ExUnit.Assertions
      assert expected == rendered
    end
  end
end

ExUnit.start()
