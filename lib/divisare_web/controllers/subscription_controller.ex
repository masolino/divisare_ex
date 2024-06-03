defmodule DivisareWeb.SubscriptionController do
  use DivisareWeb, :controller

  alias Divisare.Subscriptions

  require Logger

  def info(conn, %{"token" => token} = _params) do
    case Subscriptions.find_subscription_by_user_token(token) do
      {:ok, subscription} ->
        render(conn, :info, token: token, subscription: subscription)

      _ ->
        :error
    end
  end

  def toggle(conn, %{"token" => token}) do
    with {:ok, _subscription} <- Subscriptions.toggle_subscription_auto_renew(token) do
      redirect(conn, to: ~p"/subscription/#{token}")
    end
  end

  def cancel(conn, %{"token" => token}) do
    with {:ok, _subscription} <- Subscriptions.interrupt_subscription(token) do
      redirect(conn, to: ~p"/subscription/#{token}")
    end
  end
end
