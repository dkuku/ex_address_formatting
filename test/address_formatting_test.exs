defmodule AddressFormattingTest do
  use ExUnit.Case
  doctest AddressFormatting
  import AddressFormatting

  test "minimal test" do
    %{"components" => components, "expected" => expected} = parse_yaml("address-formatting/testcases/other/xx.yaml")
    template = 
      """
      {{{city}}}
      {{{state}}}
      {{{country}}}
      """
    assert expected == render(template, components)
  end

  test "minimal not fake test" do
    %{"components" => components, "expected" => expected} = parse_yaml("address-formatting/testcases/other/null.yaml")
    template = 
      """
      {{{island}}}
      """
    assert expected == render(template, components)
  end
end
