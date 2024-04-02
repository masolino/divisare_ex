defmodule Divisare.Utils.Countries do
  @moduledoc """
  Provides utilities to handle country data.
  """
  @countries_subdivisions Countries.all()
                          |> Enum.reduce([], fn c, acc ->
                            [{String.to_atom(c.name), c.alpha2} | acc]
                          end)
                          |> List.keysort(0)
                          |> Enum.map(fn {_, v} ->
                            {String.to_atom(v),
                             Countries.filter_by(:alpha2, v)
                             |> List.first()
                             |> Countries.Subdivisions.all()
                             |> Enum.reject(&is_nil(&1.name))
                             |> Enum.reduce([], fn s, acc ->
                               [%{s.name => to_string(s.id)} | acc]
                             end)
                             |> Enum.reverse()}
                          end)

  def all() do
    Countries.all()
    |> Enum.reduce([], fn c, acc -> [{String.to_atom(c.name), c.alpha2} | acc] end)
    |> List.keysort(0)
  end

  def by_region(region) do
    Countries.filter_by(:region, region)
    |> Enum.reduce([], fn c, acc -> [{String.to_atom(c.name), c.alpha2} | acc] end)
    |> List.keysort(0)
    
  end

  def countries_subdivisions() do
    @countries_subdivisions
  end
end
