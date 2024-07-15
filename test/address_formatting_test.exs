defmodule AddressFormattingTest do
  use ExUnit.Case
  doctest AddressFormatting
  require AddressHelper

  test "addresses" do
    for input_tuple <-
          AddressHelper.load_testcases_other() do
      AddressHelper.assert_render(input_tuple)
    end

    {success, failed} =
      for {_, data} = input_tuple <-
            AddressHelper.load_testcases_countries(),
          data != %{},
          reduce: {0, 0} do
        {success, fail} ->
          if AddressHelper.assert_render(input_tuple) do
            {success + 1, fail}
          else
            {success, fail + 1}
          end
      end

    """
    -------------------------------------
    Ran #{success + failed} tests at #{Date.utc_today()}
    #{trunc(100 * success / (success + failed))}% successfully
    #{success} success
    #{failed} failed
    -------------------------------------
    """
    |> AddressHelper.log_to_readme()
    |> IO.puts()
  end
end
