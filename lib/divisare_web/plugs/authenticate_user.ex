defmodule DivisareWeb.Plugs.AuthenticateUser do
  @moduledoc """
  Authenticates connection if session exists.

  ## Examples

      plug MyApp.Plugs.AuthenticateUser
  """

  import Plug.Conn
  alias Divisare.Accounts

  def init(opts), do: opts

  @doc """
  Assigns `current_user` to `conn`, so it is possible to always retrieve the
  user via `conn.assigns.current_user`.
  """
  def call(conn, _opts) do
    with user_id when not is_nil(user_id) <-
           get_in(conn, [Access.key(:assigns), Access.key(:current_user_id)]),
         {:ok, user} <- Accounts.find_user_by_id(user_id) do
      assign(conn, :current_user, user)
    else
      _ -> conn
    end
  end
end
