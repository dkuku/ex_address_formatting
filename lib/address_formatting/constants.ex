defmodule AddressFormatting.Constants do
  alias AddressFormatting.FileHelpers

  @state_codes FileHelpers.load_yaml_reverse("state_codes")
  @county_codes FileHelpers.load_yaml_reverse("county_codes")
  @country2lang FileHelpers.load_yaml("country2lang")
  @components FileHelpers.load_components()
  @worldwide FileHelpers.load_yaml("worldwide", directory: "countries")

  @fallback_template get_in(@worldwide, ["default", "fallback_template"])
                     |> :bbmustache.parse_binary()
  @worldwide_templates :maps.filtermap(
                         fn
                           _k, v when is_map_key(v, "address_template") ->
                             {true, :bbmustache.parse_binary(v["address_template"])}

                           _, _ ->
                             false
                         end,
                         @worldwide
                       )
  @worldwide_data :maps.filtermap(
                    fn
                      _k, v when is_map(v) ->
                        {true, :maps.without(["address_template", "fallback_template"], v)}

                      _, _ ->
                        false
                    end,
                    @worldwide
                  )

  @all_components FileHelpers.load_abbreviations()

  @standard_keys Map.keys(@components)
  def standard_keys(), do: @standard_keys
  def get_codes_dict("state"), do: @state_codes
  def get_codes_dict("county"), do: @county_codes
  def country2lang(), do: @country2lang
  def components(), do: @components
  def worldwide_templates(), do: @worldwide_templates
  def worldwide_data(), do: @worldwide_data
  def fallback_template(), do: @fallback_template
  def all_components(), do: @all_components
end
