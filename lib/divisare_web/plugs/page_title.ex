defmodule DivisareWeb.Plugs.PageTitle do
  @moduledoc """
  Sets a page title.

  ## Examples

      plug DivisareWeb.Plugs.PageTitle, title: "My fancy page"
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    assign(conn, :page_title, opts[:title])
  end
end
