defmodule Divisare.Services.Stripe do
  alias Stripe.Customer
  alias Stripe.Subscription

  def subscribe_customer(email, price_id) do
    with {:ok, customer_id} <- find_or_create_stripe_customer(email),
         {:ok, subscription} <- create_stripe_subscription(price_id, customer_id) do
      {:ok, subscription}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  # TODO: when changing email on divisare, update on stripe too.
  def find_or_create_stripe_customer(email) do
    with {:ok, %{data: []}} <- Customer.search(%{query: "email:'#{email}'", limit: 1}),
         {:ok, customer} <- Customer.create(%{email: email}) do
      {:ok, customer.id}
    else
      {:ok, %{data: [customer | _]}} -> {:ok, customer.id}
      {:error, err} -> {:error, err.message}
    end
  end

  def get_payment_intent(payment_intent_id) do
    with {:ok, payment_intent} <- Stripe.PaymentIntent.retrieve(payment_intent_id) do
      {:ok, payment_intent}
    else
      {:error, err} -> {:error, err.message}
    end
  end

  def get_customer_from_payment_intent(pi_id) do
    with {:ok, payment_intent} <- get_payment_intent(pi_id),
         {:ok, customer} <- Stripe.Customer.retrieve(payment_intent.customer) do
      {:ok, customer}
    else
      {:error, err} -> {:error, err}
    end
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
