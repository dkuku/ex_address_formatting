defmodule AddressFormattingTest do
  use ExUnit.Case
  doctest AddressFormatting
  require AddressHelper
  alias AddressFormatting.FileHelpers
  @test_path "address-formatting/testcases"

  for input_tuple <- FileHelpers.load_directory(@test_path, "other") do
    {file,
     %{
       "components" => components,
       "description" => description,
       "expected" => expected
     }} = input_tuple

    {template, variables, _} = data = AddressFormatting.get_template(components)
    rendered = AddressFormatting.render(data)

    describe file do
      test description do
        assert unquote(expected) == unquote(rendered)
      end
    end
  end

  for input_tuple <- FileHelpers.load_directory(@test_path, "countries"),
      elem(input_tuple, 1) != %{} do
    {country,
     %{
       "components" => components,
       "description" => description,
       "expected" => expected
     }} = input_tuple

    {template, variables, _} = data = AddressFormatting.get_template(components)
    rendered = AddressFormatting.render(data)

    describe "Country: " <> country do
      test description do
        assert unquote(expected) == unquote(rendered)
      end
    end
  end
end
