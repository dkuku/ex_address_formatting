defmodule AddressFormattingTest do
  use ExUnit.Case
  doctest AddressFormatting
  require TestHelper

  test "addresses" do
    for input_tuple <-
          AddressFormatting.FileHelpers.load_testcases_other() do
      TestHelper.assert_render(input_tuple, &AddressFormatting.render/1)
    end

    :rand.seed(:exsss, {1, 2, 6})

    for {_, data} = input_tuple <-
          AddressFormatting.FileHelpers.load_testcases_countries() |> Enum.shuffle(),
        reduce: {0, 0} do
      {success, fail} ->
        IO.inspect({success, fail})

        if data["expected"] == AddressFormatting.render(data["components"]) do
          {success + 1, fail}
        else
          IO.inspect(data["components"])
          IO.inspect(data["expected"])
          IO.inspect(AddressFormatting.render(data["components"]))
          {success, fail + 1}
          # TestHelper.assert_render(input_tuple, &AddressFormatting.render/1)
        end
    end
  end
end
