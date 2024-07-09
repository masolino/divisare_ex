defmodule DivisareWeb.SubscriptionController do
  use DivisareWeb, :controller

  alias Divisare.Accounts
  alias Divisare.Subscriptions
  alias Divisare.Stripe, as: StripeService

  require Logger

  plug DivisareWeb.Plugs.RequireUserMembership when action not in [:info]
  plug DivisareWeb.Plugs.PageTitle, title: "Your subscription"

  def info(conn, %{"token" => token} = _params) do
    with {:ok, user} <- Accounts.find_user_by_token(token),
         {:ok, %{stripe_subscription_id: stripe_subscription_id}} <-
           Subscriptions.find_subscription_by_user_token(token),
         {:ok, %{latest_invoice: invoice_id}} <-
           StripeService.get_subscription(stripe_subscription_id),
         {:ok, %{hosted_invoice_url: invoice_url}} <- StripeService.get_invoice(invoice_id) do
      enrollment = find_user_enrollment(conn, user)
      render(conn, :info, token: token, enrollment: enrollment, invoice_url: invoice_url)
    else
      _ -> redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}/subscriptions")
    end
  end

  def toggle(conn, %{"token" => token}) do
    with {:ok, _subscription} <- Subscriptions.toggle_subscription_auto_renew(token) do
      redirect(conn, to: ~p"/subscription/#{token}")
    else
      _ -> redirect(conn, to: ~p"/subscription/#{token}")
    end
  end

  def cancel(conn, %{"token" => token}) do
    with {:ok, _subscription} <- Subscriptions.interrupt_subscription(token) do
      redirect(conn, to: ~p"/subscription/#{token}")
    end
  end

  defp find_user_enrollment(conn, user) do
    case Subscriptions.guess_user_enrollment(user) do
      {:subscription, sub} ->
        {:subscription, sub}

      {:team, team} ->
        {:team, team}

      {:board, board} ->
        {:board, board}

      {:error, _} ->
        redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}/subscriptions")
    end
  end
end
