defmodule AddressFormattingTest do
  use ExUnit.Case
  doctest AddressFormatting
  require AddressHelper

  test "addresses" do
    for input_tuple <-
          AddressFormatting.FileHelpers.load_testcases_other() do
      AddressHelper.assert_render(input_tuple, &AddressFormatting.render/1)
    end

    :rand.seed(:exsss, {1, 2, 6})

    {success, failed} =
      for {_, data} = input_tuple <-
            AddressFormatting.FileHelpers.load_testcases_countries() |> Enum.shuffle(),
          reduce: {0, 0} do
        {success, fail} ->
          if AddressHelper.assert_render(input_tuple, &AddressFormatting.render/1) do
            {success + 1, fail}
          else
            {success, fail + 1}
          end
      end

    """
    -------------------------------------
    Ran #{success + failed} tests 
    #{trunc(100 * success / (success + failed))}% successfully
    #{success} success
    #{failed} failed
    -------------------------------------
    """
    |> AddressHelper.log_to_readme
    |> IO.puts
  end
end
