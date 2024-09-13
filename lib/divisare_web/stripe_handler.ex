defmodule DivisareWeb.StripeHandler do
  @behaviour Stripe.WebhookHandler

  require Logger

  alias Divisare.Invoices
  alias Divisare.Subscriptions
  alias Divisare.PaymentMethods

  @impl true
  def handle_event(%Stripe.Event{
        type: "payment_method.attached",
        data: %{object: %Stripe.PaymentMethod{id: pm_id, customer: customer_id}}
      }) do
    Logger.info("[webhook] Updating payment method for customer #{customer_id}")
    PaymentMethods.update_default_payment_method(customer_id, pm_id)
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "invoice.payment_failed",
        data: %{object: %Stripe.Invoice{subscription: subscription_id}}
      }) do
    Logger.warning("[webhook] Payment failed. Cancelling subscription: #{subscription_id}")
    Subscriptions.cancel_subscription(subscription_id)
    Invoices.remove_history_invoice_subscription(subscription_id)
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "invoice.payment_succeeded",
        data: %{
          object: %Stripe.Invoice{
            billing_reason: "subscription_cycle",
            subscription: subscription_id,
            period_end: period_end
          }
        }
      }) do
    {:ok, expiration_datetime} = DateTime.from_unix(period_end)
    Logger.info("[webhook] Renewing subscription #{subscription_id} until: #{DateTime.to_date(expiration_datetime)}")
    Subscriptions.cycle_subscription(subscription_id, expiration_datetime)
    Invoices.add_history_invoice(subscription_id)
    :ok
  end

  def handle_event(%Stripe.Event{
        type: "invoice.payment_succeeded",
        data: %{
          object: %Stripe.Invoice{
            billing_reason: "subscription_create",
            subscription: subscription_id
          }
        }
      }) do
    Logger.info("[webhook] Stripe subscription: #{subscription_id} created")
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: evt}) do
    Logger.info("[webhook] Unhandled Stripe event: #{evt}")
    :ok
  end
end
