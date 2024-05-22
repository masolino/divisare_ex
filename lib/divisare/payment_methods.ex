defmodule Divisare.PaymentMethods do
  alias Divisare.Subscriptions
  alias Divisare.Stripe, as: StripeService

  require Logger

  def get_setup_intent(user_token) do
    with {:ok, %{stripe_customer_id: customer_id}} <-
           Subscriptions.find_subscription_by_user_token(user_token),
         {:ok, setup_intent} <- StripeService.create_setup_intent(customer_id) do
      {:ok, setup_intent}
    end
  end

  def update_default_paymment_method(customer_id, payment_method_id) do
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
end
