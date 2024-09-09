defmodule DivisareWeb.Plugs.RequireUserAuthentication do
  @moduledoc """
  Checks for authenticated users, in case the user is not logged in, it will
  redirect the request to the option :not_logged_in_path.

  ## Examples

      plug DivisareWeb.Plugs.RequireUserAuthentication
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case Map.get(conn.assigns, :current_user, nil) do
      nil ->
        url = Path.join(Application.get_env(:divisare, :main_host, ""), "login")

        conn
        |> redirect(external: url)
        |> halt

      _user ->
        conn
    end
  end
end
