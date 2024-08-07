defmodule Divisare.PaymentMethods do
  alias Divisare.Subscriptions
  alias Divisare.Stripe, as: StripeService

  require Logger

  def get_customer_current_payment_method(user_id) do
    with {:ok, %{stripe_customer_id: customer_id}} <-
           Subscriptions.find_subscription_by_user_id(user_id),
         {:ok, payment_method} <-
           StripeService.get_customer_payment_method(customer_id) do
      parse_payment_method(payment_method)
    else
      _ -> "No payment method found."
    end
  end

  def get_setup_intent(user_id) do
    with {:ok, %{stripe_customer_id: customer_id}} <-
           Subscriptions.find_subscription_by_user_id(user_id),
         {:ok, setup_intent} <- StripeService.create_setup_intent(customer_id) do
      {:ok, setup_intent}
    end
  end

  def update_default_payment_method(customer_id, payment_method_id) do
    with {:ok, _} <- StripeService.update_customer_payment_method(customer_id, payment_method_id),
         {:ok, %{stripe_subscription_id: subscription_id}} <-
           Subscriptions.find_subscription_by_stripe_customer(customer_id),
         {:ok, _} <-
           StripeService.update_subscription_payment_method(subscription_id, payment_method_id) do
      Logger.info("Updated payment method for customer #{customer_id}")
      :ok
    else
      {:error, err} ->
        Logger.error(
          "Error updating stripe payment method for customer #{customer_id}: #{inspect(err)}"
        )
    end
  end

  defp parse_payment_method(%{type: "card", card: card}) do
    String.upcase(card.brand) <> " ending with *" <> card.last4
  end

  defp parse_payment_method(%{type: "sepa_debit"}), do: "SEPA Debit"

  defp parse_payment_method(%{type: pm_type}) do
    pm_type
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
  end
end
