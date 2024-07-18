defmodule DivisareWeb.PaymentController do
  use DivisareWeb, :controller

  alias Divisare.PaymentMethods

  require Logger

  plug DivisareWeb.Plugs.RequireUserAuthentication,
    not_logged_in_url: "#{Application.get_env(:divisare, :main_host)}/login"

  plug DivisareWeb.Plugs.RequireUserMembership
  plug DivisareWeb.Plugs.PageTitle, title: "Change payment method"

  def info(conn, _params) do
    current = PaymentMethods.get_customer_current_payment_method(conn.assigns.current_user_id)

    case PaymentMethods.get_setup_intent(conn.assigns.current_user_id) do
      {:ok, %{client_secret: client_secret}} ->
        render(conn, :info, client_secret: client_secret, current: current)

      {:error, err} ->
        Logger.error("Error retrieving setup intent #{inspect(err)}")
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def complete(conn, _params) do
    render(conn, :complete)
  end
end
