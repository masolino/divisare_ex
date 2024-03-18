defmodule DivisareWeb.StripeHandler do
  @behaviour Stripe.WebhookHandler

  require Logger

  @impl true
  # def handle_event(%Stripe.Event{type: "invoice.payment_succeeded", object: %Stripe.Invoice{customer: customer_id, customer_email: email, lines: %{data: [data | _]}}}) do
  #   # Everything should be ok, no need to update
  #   :ok
  # end

  @impl true
  def handle_event(%Stripe.Event{type: "payment_intent.payment_failed", object: %Stripe.PaymentIntent{id: pi_id}}) do
    # Find the payment intent and get the customer
    # Find customer subscription and cancel it
    Logger.warn("Payment intent failed: #{pi_id}")
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: event}) do

    Logger.info("Unhandled Stripe event: #{event}")
    :ok
  end
end
