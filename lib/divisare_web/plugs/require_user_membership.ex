defmodule DivisareWeb.Plugs.RequireUserMembership do
  @moduledoc """
  Requires user to have at least some kind of membership or subscription.

  ## Examples

      plug DivisareWeb.Plugs.RequireUserMembership
  """

  alias Divisare.Subscriptions
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:user, user} when not is_nil(user) <- {:user, conn.assigns.current_user},
         {kind, _sub} when kind not in [:error] <- Subscriptions.guess_user_enrollment(user) do
      conn
    else
      _ -> redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}/subscriptions")
    end
  end
end
