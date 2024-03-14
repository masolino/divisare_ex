defmodule Divisare.Utils do
  @moduledoc """
  This module defines some helpers useful for development.
  """

  use Timex

  @doc """
  Returns a regex to validate email format.
  """
  def email_regex do
    # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
    ~r/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  end


  @doc """
  Returns a random URL-safe string.
  """
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @doc """
  Beautify UTC DateTime and convert to local timezone string.
  """
  def format_date(%DateTime{} = datetime) do
    timezone = Timex.timezone("Europe/Rome", Timex.now())

    Timezone.convert(datetime, timezone)
    |> Timex.format!("%d/%m/%Y %H:%M", :strftime)
  end

  def format_date(%NaiveDateTime{} = date) do
    date |> Timex.format!("%d/%m/%Y %H:%M", :strftime)
  end

  def format_date(%Date{} = date) do
    date |> Timex.format!("%d/%m/%Y", :strftime)
  end

  def format_date(nil), do: ""

  @doc """
  Sluggify string.
  """
  def sluggify(string) when is_binary(string) do
    string
    |> String.replace(" ", "-")
    |> String.downcase()
  end

  def sluggify(_), do: ""

  def truncate(string, length \\ 30)

  def truncate(string, length) when is_binary(string) and is_integer(length) do
    case String.length(string) > length do
      false ->
        string

      true ->
        str = String.slice(string, 0..length)
        str <> "..."
    end
  end

  def truncate(_, _), do: ""
end
