defmodule AddressFormatting do
  @moduledoc """
  Documentation for `AddressFormatting`.
  """
  alias AddressFormatting.Constants
  alias AddressFormatting.Address

  def render(variables) when is_map(variables) do
    case get_template(variables) do
      {nil, _, _} ->
        variables
        |> Map.delete("country_code")
        |> Map.values()
        |> Enum.join("\n")
        |> Kernel.<>("\n")

      data ->
        render(data)
    end
  end

  @spec render({String.t(), Address.t() | map, list}) :: String.t()
  def render({template, address, postformat}) do
    :bbmustache.compile(template, address, key_type: :atom)
    |> String.trim()
    |> run_postformat(postformat)
    |> fix_duplicates(address)
    |> Kernel.<>("\n")
  end

  def fix_duplicates(string, _variables) do
    string
    |> String.split("\n")
    |> List.foldr([], fn current, acc ->
      previous = List.first(acc)

      if current == previous do
        acc
      else
        [current | acc]
      end
    end)
    |> Enum.join("\n")
  end

  def run_postformat(rendered, postformat) do
    postformat
    |> Enum.reduce(rendered, fn [from, to], rendered_acc ->
      Regex.replace(from, rendered_acc, to)
    end)
  end

  def run_replace(address, country_data) do
    address_new =
      country_data
      |> Map.get("replace", [])
      |> Enum.reduce(address, fn [field_from, to], variables ->
        [field, from] =
          case String.split(field_from, "=") do
            [from | []] -> [:country, from]
            ["country_code", from] -> [:country_code, String.upcase(from)]
            [field, from] -> [String.to_existing_atom(field), from]
          end

        case Map.get(variables, field) do
          nil -> variables
          ^from -> Map.put(variables, field, to)
          _ -> variables
        end
      end)

    {:ok, address_new}
  end

  def get_template(variables) do
    country_code = Map.get(variables, "country_code") |> upcase()

    case Map.get(Constants.worldwide_data(), country_code) do
      nil ->
        {
          Constants.fallback_template(),
          struct(Address, variables),
          []
        }

      country_data ->
        with address <- %Address{},
             {:ok, address} <- check_country_case(address, variables, country_data),
             {:ok, address} <- convert_component_aliases(address, variables),
             {:ok, address} <- convert_constants(address),
             {:ok, address} <- convert_country_numeric(address),
             {:ok, address} <- add_codes(address, :county_code),
             {:ok, address} <- add_codes(address, :state_code),
             {:ok, address} <- run_replace(address, country_data),
             {:ok, address} <- check_use_country(address, country_data),
             {:ok, address} <- add_component(address, country_data),
             {:ok, address} <- check_change_country(address, country_data),
             {:ok, postformat} <- get_postformat(country_data) do
          {
            get_in(Constants.worldwide_templates(), [String.upcase(address.country_code)]),
            address,
            postformat
          }
        end
    end
  end

  def default_postformat_regex() do
    [
      [~r/\&#39\;/, "'"],
      [~r/[\},\s]+$/, ""],
      [~r/^[,\s]+/, ""],
      # linestarting with dash due to a parameter missing
      [~r/^- /, ""],
      [~r/\n\h-/, "\n"],
      # multiple commas to one
      [~r/,\s*,/, ", "],
      # one horiz whitespace behind comma
      [~r/\h+,\h+/, ", "],
      # multiple horiz whitespace to one
      [~r/\h\h+/, " "],
      # horiz whitespace, newline to newline
      [~r/\h\n/, "\n"],
      # newline comma to just newline
      [~r/\n,/, "\n"],
      # multiple commas to one
      [~r/,,+/, ","],
      # comma newline to just newline
      [~r/,\n/, "\n"],
      # newline plus space to newline
      [~r/\n\h+/, "\n"],
      [~r/\n\n+/, "\n"]
    ]
  end

  def get_postformat(country_data) do
    postformat =
      case Map.get(country_data, "postformat_replace") do
        nil ->
          default_postformat_regex()

        postformat_regex_list ->
          postformat_regex_list
          |> Enum.reduce(default_postformat_regex(), fn [from, to], postformat_acc ->
            from = Regex.compile!(from)
            to = String.replace(to, "$", "\\")
            [[from, to] | postformat_acc]
          end)
      end

    {:ok, postformat}
  end

  def add_component(address, country_data) do
    case Map.get(country_data, "add_component") do
      nil ->
        {:ok, address}

      add_component ->
        case String.split(add_component, "=") do
          ["country_code", value] ->
            {:ok, %Address{address | country_code: value}}

          [field, value] ->
            {:ok, Map.put(address, to_existing_atom(field, :attention), value)}
        end
    end
  end

  def convert_component_aliases(address, variables) do
    components = Constants.components()

    address =
      variables
      |> Enum.reduce(address, fn {key, v}, acc_add ->
        atom_key = to_existing_atom(key, :attention)

        case Map.get(components, atom_key) do
          nil ->
              %Address{acc_add | attention: v}

          new_key ->
            atom_key = to_existing_atom(new_key, :attention)
            new_value = adjust_value(v, atom_key)
              Map.put(acc_add, atom_key, new_value)
        end
      end)

    {:ok, address}
  end

  def convert_constants(address) do
    variables =
      case Map.get(address, :country_code) do
        "UK" ->
          Map.put(address, :country_code, "GB")

        "NL" ->
          state = Map.get(address, :state)

          cond do
            state == nil ->
              address

            state == "Curaçao" ->
              %{address | country: "Curaçao", country_code: "CW"}

            String.downcase(state) =~ "sint maarten" ->
              %{address | country: "Sint Maarten", country_code: "SX"}

            String.downcase(state) =~ "aruba" ->
              %{address | country: "Aruba", country_code: "AW"}

            true ->
              address
          end

        _other ->
          address
      end

    {:ok, address}
  end

  def convert_country_numeric(address) do
    address =
      if is_integer?(address.country) do
        %Address{address | country: address.state, state: nil}
      else
        address
      end

    {:ok, address}
  end

  def add_codes(address, key) do
    country_code = address.country_code

    updated_address =
      case Map.get(address, key) do
        nil ->
          address

        state ->
          case get_in(Constants.get_codes_dict(key), [country_code, state]) do
            nil -> address
            code -> Map.put(address, key, code)
          end
      end

    {:ok, address}
  end

  def check_change_country(address, country_data) do
    case Map.get(country_data, "change_country") do
      nil ->
        {:ok, address}

      change_country ->
        {:ok, %Address{address | country: change_country}}
    end
  end

  def check_country_case(address, variables, _country_data) do
    country_code = Map.get(variables, "country_code")
    {:ok, Map.put(address, :country_code, String.upcase(country_code))}
  end

  def check_use_country(address, country_data) do
    case Map.get(country_data, "use_country") do
      nil -> {:ok, address}
      country_code -> {:ok, %Address{address | country_code: String.upcase(country_code)}}
    end
  end

  def upcase(nil), do: nil
  def upcase(string), do: String.upcase(string)
  def is_integer?(val) when is_integer(val), do: true

  def is_integer?(val) when is_bitstring(val) do
    Regex.match?(~r{\A\d*\z}, val)
  end

  def is_integer?(_), do: false

  def adjust_value(value, :postcode) when is_bitstring(value) and byte_size(value) > 9, do: nil
  def adjust_value(value, key), do: value

  def to_existing_atom(key, _) when is_atom(key), do: key
  def to_existing_atom(key, default) do
    try do
      String.to_existing_atom(key)
    rescue
      e ->
        IO.puts("#{key}: is not an existing atom")
        default
    end
  end
end
