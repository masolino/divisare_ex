defmodule DivisareWeb.Plugs.RequireUserActiveMembership do
  @moduledoc """
  Requires user to have at least some kind of active membership or subscription.

  ## Examples

      plug DivisareWeb.Plugs.RequireUserActiveMembership
  """

  alias Divisare.Subscriptions
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:user, user} when not is_nil(user) <- {:user, conn.assigns.current_user},
         {kind, sub} <- Subscriptions.guess_user_enrollment(user),
         true <- Subscriptions.check_user_enrollment_is_active({kind, sub}) do
      conn
    else
      _ -> redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}/subscriptions")
    end
  end
end
