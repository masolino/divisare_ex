defmodule DivisareWeb.PaymentController do
  use DivisareWeb, :controller

  alias Divisare.PaymentMethods

  require Logger

  def info(conn, %{"token" => token} = _params) do
    case PaymentMethods.get_setup_intent(token) do
      {:ok, %{client_secret: client_secret}} ->
        render(conn, :info, token: token, client_secret: client_secret)

      {:error, err} ->
        Logger.error(IO.inspect(err))
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def complete(conn, %{"token" => _token} = _params) do
    render(conn, :complete)
  end
end