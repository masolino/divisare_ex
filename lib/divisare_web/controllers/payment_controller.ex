defmodule DivisareWeb.PaymentController do
  use DivisareWeb, :controller

  alias Divisare.PaymentMethods

  require Logger

  plug DivisareWeb.Plugs.PageTitle, title: "Change payment method"

  def info(conn, %{"token" => token} = _params) do
    current = PaymentMethods.get_customer_current_payment_method(token)

    case PaymentMethods.get_setup_intent(token) do
      {:ok, %{client_secret: client_secret}} ->
        render(conn, :info, token: token, client_secret: client_secret, current: current)

      {:error, err} ->
        Logger.error("Error retrieving setup intent #{inspect(err)}")
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def complete(conn, %{"token" => _token} = _params) do
    render(conn, :complete)
  end
end
