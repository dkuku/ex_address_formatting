defmodule AddressFormatting do
  @moduledoc """
  Documentation for `AddressFormatting`.
  """
  alias AddressFormatting.FileHelpers

  @state_codes FileHelpers.load_yaml("state_codes")
  @county_codes FileHelpers.load_yaml("county_codes")
  @country_codes FileHelpers.load_yaml("country_codes")
  @country2lang FileHelpers.load_yaml("country2lang")
  @components FileHelpers.load_components()
  @worldwide FileHelpers.load_yaml("worldwide", directory: "countries")
  @all_components FileHelpers.load_abbreviations()

  @standard_keys ["island"] ++ Map.keys(@components)
  def state_codes(), do: @state_codes
  def county_codes(), do: @county_codes
  def country_codes(), do: @country_codes
  def country2lang(), do: @country2lang
  def load_components(), do: @components
  def load_worldwide(), do: @worldwide
  def all_components(), do: @all_components
  def standard_keys(), do: @standard_keys

  def render(variables) when is_map(variables) do
    case get_template(variables) do
      {nil, _} ->
        variables
        |> Map.delete("country_code")
        |> Map.values()
        |> Enum.join("\n")
        |> Kernel.<>("\n")

      {template, updated_variables} ->
        render({template, updated_variables})
    end
  end

  def render({template, variables}) do
    first_function = fn string, render_fn ->
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

    variables = Map.put(variables, "first", first_function)
    template = :bbmustache.parse_binary(template)

    :bbmustache.compile(template, variables, key_type: :binary)
    |> String.trim()
    |> run_postformat_replace(variables)
    |> fix_duplicates(variables)
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

  def run_postformat_replace(rendered, variables) do
    variables
    |> Map.get("postformat_replace", [])
    |> Enum.reduce(rendered, fn [from, to], rendered_acc ->
      Regex.replace(from, rendered_acc, to)
    end)
  end

  def run_replace(variables_org, country_data) do
    variables_new =
      country_data
      |> Map.get("replace", [])
      |> Enum.reduce(variables_org, fn [field_from, to], variables ->
        [field, from] =
          case String.split(field_from, "=") do
            [from | []] -> ["country", from]
            [field, from] -> [field, from]
          end

        case Map.get(variables, field) do
          nil -> variables
          ^from -> Map.put(variables, field, to)
          _ -> variables
        end
      end)

    {:ok, variables_new}
  end

  def get_template(variables) do
    country_code = Map.get(variables, "country_code") |> upcase()

    case Map.get(@worldwide, country_code) do
      nil ->
        {get_in(@worldwide, ["default", "fallback_template"]), variables}

      country_data ->
        with {:ok, variables} <- check_country_case(variables, country_data),
             {:ok, variables} <- convert_component_aliases(variables, country_data),
             {:ok, variables} <- convert_keys_to_attention(variables, country_data),
             {:ok, variables} <- convert_to_code(variables, country_data),
             {:ok, variables} <- add_postformat(variables, country_data),
             {:ok, variables} <- run_replace(variables, country_data),
             {:ok, variables} <- check_use_country(variables, country_data),
             {:ok, variables} <- add_component(variables, country_data),
             {:ok, variables} <- check_change_country(variables, country_data) do
          {get_in(@worldwide, [variables["country_code"], "address_template"]), variables}
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

  def add_postformat(variables, country_data) do
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

    {:ok, Map.put(variables, "postformat_replace", postformat)}
  end

  def add_component(variables, country_data) do
    case Map.get(country_data, "add_component") do
      nil ->
        {:ok, variables}

      add_component ->
        [field, value] = String.split(add_component, "=")

        {:ok, Map.put(variables, field, value)}
    end
  end

  def convert_component_aliases(variables, _country_data) do
    variables =
      variables
      |> Enum.reduce(variables, fn {key, v}, acc ->
        case Map.get(@components, key) do
          nil ->
            Map.put(acc, key, v)

          new_key ->
            Map.put(acc, new_key, v)
        end
      end)

    {:ok, variables}
  end

  def convert_to_code(variables, _country_data) do
    {:ok, variables}
  end

  def convert_keys_to_attention(variables, _country_data) do
    attention =
      variables
      |> Map.drop(@standard_keys)
      |> Map.values()
      |> Enum.join(", ")

    if attention do
      {:ok, Map.put(variables, "attention", attention)}
    else
      {:ok, variables}
    end
  end

  def check_change_country(variables, country_data) do
    case Map.get(country_data, "change_country") do
      nil ->
        {:ok, variables}

      change_country ->
        {:ok, Map.replace(variables, "country", change_country)}
    end
  end

  def check_country_case(variables, _country_data) do
    {:ok, Map.update!(variables, "country_code", &String.upcase/1)}
  end

  def check_use_country(variables, country_data) do
    case Map.get(country_data, "use_country") do
      nil -> {:ok, variables}
      country_code -> {:ok, Map.put(variables, "country_code", country_code)}
    end
  end

  def upcase(nil), do: nil
  def upcase(string), do: String.upcase(string)
end
