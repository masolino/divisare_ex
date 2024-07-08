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
                  {:Greece, "GR"},
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
                  {:Netherlands, "NL"},
                  {:Poland, "PL"},
                  {:Portugal, "PT"},
                  {:Romania, "RO"},
                  {:Sweden, "SE"},
                  {:Slovenia, "SI"},
                  {:Slovakia, "SK"},
                  {:"Northern Ireland", "GB-NIR"}
                ]
                |> List.keysort(0)

  @eu_countries_vies [
                       {:AT, "AT"},
                       {:BE, "BE"},
                       {:BG, "BG"},
                       {:CY, "CY"},
                       {:CZ, "CZ"},
                       {:DE, "DE"},
                       {:DK, "DK"},
                       {:EE, "EE"},
                       {:GR, "EL"},
                       {:ES, "ES"},
                       {:FI, "FI"},
                       {:FR, "FR"},
                       {:HR, "HR"},
                       {:HU, "HU"},
                       {:IE, "IE"},
                       {:IT, "IT"},
                       {:LT, "LT"},
                       {:LU, "LU"},
                       {:LV, "LV"},
                       {:MT, "MT"},
                       {:NL, "NL"},
                       {:PL, "PL"},
                       {:PT, "PT"},
                       {:RO, "RO"},
                       {:SE, "SE"},
                       {:SI, "SI"},
                       {:SK, "SK"},
                       {:"GB-NIR", "XI"}
                     ]
                     |> List.keysort(0)

  @northern_ireland_subdivisions [
    %{"Antrim" => "Antrim"},
    %{"Armagh" => "Armagh"},
    %{"Downpatrick" => "Downpatrick"},
    %{"Enniskillen" => "Enniskillen"},
    %{"Coleraine" => "Coleraine"},
    %{"Omag" => "Omag"}
  ]

  @eu_countries_subdivisions @eu_countries
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
                                    |> Enum.sort()
                                end}
                             end)
                             |> Enum.reject(fn {_, v} -> is_nil(v) end)

  def eu_countries() do
    @eu_countries
  end

  def eu_countries_vies() do
    @eu_countries_vies
  end

  def eu_countries_subdivisions() do
    @eu_countries_subdivisions ++ [{:"GB-NIR", @northern_ireland_subdivisions}]
  end
end
