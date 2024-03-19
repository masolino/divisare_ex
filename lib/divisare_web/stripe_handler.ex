defmodule DivisareWeb.StripeHandler do
  @behaviour Stripe.WebhookHandler

  require Logger

  alias Divisare.Services.Stripe, as: StripeService
  alias Divisare.Subscriptions

  # @impl true
  # def handle_event(%Stripe.Event{type: "invoice.payment_succeeded", object: %Stripe.Invoice{customer: customer_id, customer_email: email, lines: %{data: [data | _]}}}) do
  #   # Everything should be ok, no need to update
  #   :ok
  # end

  @impl true
  def handle_event(%Stripe.Event{
        type: "payment_intent.payment_failed",
        data: %{object: %Stripe.PaymentIntent{id: pi_id}}
      }) do
    {:ok, customer} = StripeService.get_customer_from_payment_intent(pi_id)
    Subscriptions.cancel_subscription_by_customer_id(customer.id)
    Logger.warn("Payment intent failed: #{pi_id}")
    Logger.info("cancelling subscription for customer: #{customer.id}")
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: evt} = event) do
    IO.inspect(event, label: "== Unhandled event")
    Logger.info("Unhandled Stripe event: #{evt}")
    :ok
  end
end
