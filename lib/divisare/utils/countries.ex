defmodule Divisare.Utils.Countries do
  @moduledoc """
  Provides utilities to handle country data.
  """

  @eu_countries [
                  {:Austria, "AT"},
                  {:Belgium, "BE"},
                  {:Bulgaria, "BG"},
                  {:Cyprus, "CY"},
                  {:Czechia, "CZ"},
                  {:Germany, "DE"},
                  {:Denmark, "DK"},
                  {:Estonia, "EE"},
                  {:Greece, "EL"},
                  {:Spain, "ES"},
                  {:Finland, "FI"},
                  {:France, "FR"},
                  {:Croatia, "HR"},
                  {:Hungary, "HU"},
                  {:Ireland, "IE"},
                  {:Italy, "IT"},
                  {:Lithuania, "LT"},
                  {:Luxembourg, "LU"},
                  {:Latvia, "LV"},
                  {:Malta, "MT"},
                  {:"The Netherlands", "NL"},
                  {:Poland, "PL"},
                  {:Portugal, "PT"},
                  {:Romania, "RO"},
                  {:Sweden, "SE"},
                  {:Slovenia, "SI"},
                  {:Slovakia, "SK"},
                  {:"Northern Ireland", "XI"}
                ]
                |> List.keysort(0)

  @countries_subdivisions @eu_countries
                          |> Enum.map(fn {_, v} ->
                            {String.to_atom(v),
                             Countries.filter_by(:alpha2, v)
                             |> List.first()
                             |> case do
                               nil ->
                                 nil

                               found ->
                                 Countries.Subdivisions.all(found)
                                 |> Enum.reject(&is_nil(&1.name))
                                 |> Enum.reduce([], fn s, acc ->
                                   [%{s.name => to_string(s.id)} | acc]
                                 end)
                                 |> Enum.reverse()
                             end}
                          end)
                          |> Enum.reject(fn {_, v} -> is_nil(v) end)

  def all() do
    @eu_countries
  end

  def countries_subdivisions() do
    @countries_subdivisions
  end
end
