defmodule DivisareWeb.SubscriptionController do
  use DivisareWeb, :controller

  alias Divisare.Subscriptions
  alias Divisare.Stripe, as: StripeService

  require Logger

  plug DivisareWeb.Plugs.RequireUserAuthentication
  plug DivisareWeb.Plugs.RequireUserMembership when action not in [:info]
  plug DivisareWeb.Plugs.PageTitle, title: "Your subscription"

  def info(conn, _params) do
    with {:ok, enrollment} <- find_user_enrollment(conn.assigns.current_user),
         {:ok, data} <- build_enrollment_data(enrollment) do
      render(conn, :info, data)
    else
      err ->
        Logger.warning("SUBSCRIPTION INFO ERROR #{inspect(err)}")
        redirect(conn, external: "#{Application.get_env(:divisare, :main_host)}/subscriptions")
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

  defp build_enrollment_data(
         {:subscription,
          %{
            stripe_subscription_id: stripe_subscription_id,
            type: "ReaderSubscription",
            stripe_customer_token: customer_id
          }} = enrollment
       ) when is_nil(stripe_subscription_id) or stripe_subscription_id == ""  do
    # sub_1Pxm9mCoZsrgQwX9SuaWLtMt
    Logger.info("FALLBACK CUSTOMER TOKEN #{customer_id} START")

    with {:ok, %{id: stripe_subscription_id}} <-
           StripeService.get_subscription_by_customer(customer_id),
         {:ok, %{latest_invoice: invoice_id}} <-
           StripeService.get_subscription(stripe_subscription_id),
         {:ok, %{hosted_invoice_url: invoice_url}} <- StripeService.get_invoice(invoice_id) do
      {:ok, %{enrollment: enrollment, invoice_url: invoice_url}}
    else
      err ->
        Logger.warning("FALLBACK CUSTOMER TOKEN ERROR #{inspect(err)}")
        {:error, "invoice url not found"}
    end
  end

  defp build_enrollment_data(
         {:subscription,
          %{stripe_subscription_id: stripe_subscription_id, type: "ReaderSubscription"}} =
           enrollment
       ) when not is_nil(stripe_subscription_id) and length(stripe_subscription_id) > 0 do
         Logger.warning("ENROLLMENT DATA SUB ID #{inspect(stripe_subscription_id)}")
    with {:ok, %{latest_invoice: invoice_id}} <-
           StripeService.get_subscription(stripe_subscription_id),
         {:ok, %{hosted_invoice_url: invoice_url}} <- StripeService.get_invoice(invoice_id) do
      {:ok, %{enrollment: enrollment, invoice_url: invoice_url}}
    else
      err ->
        Logger.warning("ENROLLMENT DATA ERROR #{inspect(err)}")
        {:error, "invoice url not found"}
    end
  end

  defp build_enrollment_data(enrollment) do
    Logger.warning("ENROLLMENT DATA NO INVOICE #{inspect(enrollment)}")
    {:ok, %{enrollment: enrollment, invoice_url: nil}}
  end
end
