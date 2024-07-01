defmodule Divisare.Stripe do
  require Logger
  alias Stripe.Customer
  alias Stripe.Subscription
  alias Stripe.Invoice
  alias Stripe.SetupIntent

  def subscribe_customer(name, email, price_id) do
    with {:ok, customer_id} <- find_or_create_stripe_customer_by_email(name, email),
         {:ok, subscription} <- create_stripe_subscription(price_id, customer_id) do
      {:ok, subscription}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def get_customer_payment_method(customer_id, payment_method_id) do
    Customer.retrieve_payment_method(customer_id, payment_method_id)
  end

  def get_subscription(subscription_id) do
    Stripe.Subscription.retrieve(subscription_id)
  end

  def toggle_subscription_auto_renew(subscription_id, disable_auto_renew) do
    Subscription.update(subscription_id, %{cancel_at_period_end: disable_auto_renew})
  end

  # TODO: when changing email on divisare, update on stripe too.
  def find_or_create_stripe_customer_by_email(name, email) do
    with {:ok, %{data: []}} <- Customer.search(%{query: "email:'#{email}'", limit: 1}),
         {:ok, customer} <- Customer.create(%{name: name, email: email}) do
      {:ok, customer.id}
    else
      {:ok, %{data: [customer | _]}} -> {:ok, customer.id}
      {:error, err} -> {:error, err.message}
    end
  end

  def update_customer_payment_method(customer_id, payment_method_id) do
    Customer.update(customer_id, %{invoice_settings: %{default_payment_method: payment_method_id}})
  end

  def update_subscription_payment_method(subscription_id, payment_method_id) do
    Subscription.update(subscription_id, %{default_payment_method: payment_method_id})
  end

  def get_payment_intent(payment_intent_id) do
    with {:ok, payment_intent} <- Stripe.PaymentIntent.retrieve(payment_intent_id) do
      {:ok, payment_intent}
    else
      {:error, err} -> {:error, err.message}
    end
  end

  def get_invoice(invoice_id) do
    Invoice.retrieve(invoice_id)
  end

  def cancel_stripe_subscription(subscription_id) do
    Subscription.cancel(subscription_id)
  end

  def create_setup_intent(customer_id) do
    SetupIntent.create(%{
      customer: customer_id,
      # automatic_payment_methods: %{enabled: true}
      payment_method_types: ["paypal", "card", "link", "sepa_debit"]
    })
  end

  defp create_stripe_subscription(price_id, customer_id) do
    payment_settings = %{
      payment_method_types: ["card", "sepa_debit", "paypal", "link"],
      save_default_payment_method: "on_subscription"
    }

    subscription_params = %{
      customer: customer_id,
      items: [%{price: price_id}],
      payment_settings: payment_settings,
      payment_behavior: "default_incomplete",
      expand: ["latest_invoice.payment_intent"]
    }

    case Subscription.create(subscription_params) do
      {:ok, subscription} -> {:ok, subscription}
      {:error, err} -> {:error, err}
    end
  end
end
