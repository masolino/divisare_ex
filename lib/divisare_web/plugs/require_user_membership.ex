defmodule DivisareWeb.Plugs.RequireUserMembership do
  @moduledoc """
  Requires user to have at least some kind of membership or subscription.

  ## Examples

      plug DivisareWeb.Plugs.RequireUserMembership
  """

  alias Divisare.Subscriptions
  alias Divisare.Accounts
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, user} <- Accounts.find_user_by_token(conn.params["token"]) do
      case Subscriptions.guess_user_enrollment(user) do
        {:error, _} ->
          redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}/subscriptions")

        _ ->
          conn
      end
    else
      _ -> redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}")
    end
  end
end
