defmodule AddressFormatting.Address do
  alias AddressFormatting.Address

  defimpl String.Chars, for: Address do
    def to_string(address) do
      address
      |> Enum.filter(fn {k, v} -> v != nil && k != :__struct__ && k != :first end)
      |> Enum.map_join("\n", fn {k, v} -> "#{k}: #{v}" end)
    end
  end

  defimpl Enumerable, for: Address do
    def count(map) do
      {:ok, map_size(map)}
    end

    def member?(map, {key, value}) do
      {:ok, match?(%{^key => ^value}, map)}
    end

    def member?(_map, _other) do
      {:ok, false}
    end

    def slice(map) do
      size = map_size(map)
      {:ok, size, &:maps.to_list/1}
    end

    def reduce(map, acc, fun) do
      Enumerable.List.reduce(:maps.to_list(map), acc, fun)
    end
  end

  def first_function(string, render_fn) do
    string
    |> render_fn.()
    |> String.split("||", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Kernel.then(fn
      [] -> ""
      [head | _] -> head
    end)
  end

  defstruct [
    :archipelago,
    :attention,
    :city,
    :city_district,
    :continent,
    :country,
    :county,
    :county_code,
    :country_code,
    :hamlet,
    :house,
    :house_number,
    :island,
    :municipality,
    :neighbourhood,
    :postal_city,
    :postcode,
    :province,
    :quarter,
    :region,
    :road,
    :state,
    :state_code,
    :state_district,
    :suburb,
    :town,
    :village,
    first: &__MODULE__.first_function/2
  ]
end
