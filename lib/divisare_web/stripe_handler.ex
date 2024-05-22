defmodule DivisareWeb.StripeHandler do
  @behaviour Stripe.WebhookHandler

  require Logger

  alias Divisare.Subscriptions
  alias Divisare.PaymentMethods

  @impl true
  def handle_event(%Stripe.Event{
        type: "payment_intent.payment_failed",
        data: %{object: %Stripe.PaymentIntent{id: pi_id}}
      }) do
    Logger.warn("Payment intent failed: #{pi_id}")
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "payment_method.attached",
        data: %{object: %Stripe.PaymentMethod{id: pm_id, customer: customer_id}}
      }) do
    PaymentMethods.update_default_paymment_method(customer_id, pm_id)
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "invoice.payment_failed",
        data: %{object: %Stripe.Invoice{subscription: subscription_id}}
      }) do
    Logger.warn("Payment failed. Cancelling subscription : #{subscription_id}")
    Subscriptions.cancel_subscription(subscription_id)

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: evt}) do
    # Logger.info("Unhandled Stripe event: #{evt}")
    :ok
  end
end
