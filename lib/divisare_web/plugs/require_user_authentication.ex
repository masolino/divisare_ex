defmodule DivisareWeb.Plugs.RequireUserAuthentication do
  @moduledoc """
  Checks for authenticated users, in case the user is not logged in, it will
  redirect the request to the option :not_logged_in_url.

  ## Examples

      plug MyApp.Plugs.RequireUserAuthentication, not_logged_in_url: "/login"
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, opts) do
    case Map.get(conn.assigns, :current_user, nil) do
      nil ->
        conn
        |> redirect(external: opts[:not_logged_in_url])
        |> halt

      _user ->
        conn
    end
  end
end
