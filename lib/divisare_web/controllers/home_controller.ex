defmodule DivisareWeb.HomeController do
  use DivisareWeb, :controller

  def index(conn, _params) do
    redirect(conn, external: Application.get_env(:divisare, :main_host))
  end
end
