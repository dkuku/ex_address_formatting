defmodule AddressFormatting.Constants do
  alias AddressFormatting.FileHelpers

  @state_codes FileHelpers.load_yaml_reverse("state_codes")
  @county_codes FileHelpers.load_yaml_reverse("county_codes")
  @country2lang FileHelpers.load_yaml("country2lang")
  @components FileHelpers.load_components() |> Map.drop(["suburb"])
  @worldwide FileHelpers.load_yaml("worldwide", directory: "countries")
  @all_components FileHelpers.load_abbreviations()

  @standard_keys ["suburb"] ++ Map.keys(@components)
  def standard_keys(), do: @standard_keys
  def get_codes_dict("state"), do: @state_codes
  def get_codes_dict("county"), do: @county_codes
  def country2lang(), do: @country2lang
  def components(), do: @components
  def worldwide(), do: @worldwide
  def all_components(), do: @all_components
end
