defmodule DivisareWeb.SubscriptionController do
  use DivisareWeb, :controller

  alias Divisare.Subscriptions
  alias Divisare.Stripe, as: StripeService

  require Logger

  plug DivisareWeb.Plugs.RequireUserAuthentication,
    not_logged_in_url: "#{Application.get_env(:divisare, :main_host)}/login"

  plug DivisareWeb.Plugs.RequireUserMembership when action not in [:info]
  plug DivisareWeb.Plugs.PageTitle, title: "Your subscription"

  def info(conn, _params) do
    with {:ok, enrollment} <- find_user_enrollment(conn.assigns.current_user),
         {:ok, data} <- build_enrollment_data(enrollment) do
          render(conn, :info, data)
    else
      _ -> redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}/subscriptions")
    end
  end

  def toggle(conn, _) do
    with {:ok, _subscription} <-
           Subscriptions.toggle_subscription_auto_renew(conn.assigns.current_user_id) do
      redirect(conn, to: ~p"/subscription")
    else
      _ -> redirect(conn, to: ~p"/subscription")
    end
  end

  defp find_user_enrollment(user) do
    case Subscriptions.guess_user_enrollment(user) do
      {:subscription, sub} -> {:ok, {:subscription, sub}}
      {:team, team} -> {:ok, {:team, team}}
      {:board, board} -> {:ok, {:board, board}}
      {:error, reason} -> {:error, "can't determine user enrollment: #{inspect(reason)}"}
    end
  end

  defp build_enrollment_data({:subscription, %{stripe_subscription_id: stripe_subscription_id, type: "ReaderSubscription"}} = enrollment) do
    with {:ok, %{latest_invoice: invoice_id}} <-
            StripeService.get_subscription(stripe_subscription_id),
          {:ok, %{hosted_invoice_url: invoice_url}} <- StripeService.get_invoice(invoice_id) do
        {:ok, %{enrollment: enrollment, invoice_url: invoice_url}}
    else
      _ -> {:error, "invoice url not found"}
    end
  end

  defp build_enrollment_data(enrollment) do
    {:ok, %{enrollment: enrollment, invoice_url: nil}}
  end
end
