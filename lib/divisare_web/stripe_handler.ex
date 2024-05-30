defmodule DivisareWeb.StripeHandler do
  @behaviour Stripe.WebhookHandler

  require Logger

  alias Divisare.Subscriptions
  alias Divisare.PaymentMethods
  alias Divisare.Invoices

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
        type: "customer.subscription.updated",
        data: %{object: %Stripe.Subscription{id: sub_id, default_payment_method: pm_id}}
      }) do
    # NOTE: this returns ok UNLESS already invoiced. We'll just ignore the error otherwise.
    Invoices.update_history_invoice_subscription(sub_id, %{
      stripe_payment_method_id: pm_id,
      paid_at: NaiveDateTime.utc_now()
    })

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "invoice.payment_failed",
        data: %{object: %Stripe.Invoice{subscription: subscription_id}}
      }) do
    Logger.warn("Payment failed. Cancelling subscription : #{subscription_id}")
    Subscriptions.cancel_subscription(subscription_id)
    # TODO: should we remove the history-invoice too?
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: evt}) do
    Logger.info("Unhandled Stripe event: #{evt}")
    :ok
  end
end
