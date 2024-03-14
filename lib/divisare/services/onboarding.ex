defmodule Divisare.Services.Onboarding do
  alias Divisare.Accounts
  alias Divisare.Subscriptions
  alias Divisare.Services.Stripe, as: StripeService

  def get_stripe_subscription_client_secret(email, price_id) do
    case StripeService.subscribe_customer(email, price_id) do
      {:ok, subscription} -> extract_client_secret_from_subscription(subscription)
      {:error, reason} -> {:error, reason}
    end
  end

  def onboard_customer(email, payment_intent_id) do
    {:ok, payment_intent} = StripeService.get_payment_intent(payment_intent_id)

    with true <- payment_intent.receipt_email == email,
         {:ok, user} <- Accounts.find_or_onboard_user(email) do
      subscription_params = %{
        email: email,
        person_id: user.id,
        expire_on: Date.utc_today() |> Timex.shift(years: 1),
        amount: Decimal.from_float(payment_intent.amount / 100),
        stripe_customer_id: payment_intent.customer,
        currency: payment_intent.currency
      }

      {:ok, subscription} = Subscriptions.create_subscription(subscription_params)

      {:ok, user, subscription}
    end
  end

  defp extract_client_secret_from_subscription(subscription) do
    client_secret =
      case subscription.pending_setup_intent do
        nil -> subscription.latest_invoice.payment_intent.client_secret
        _ -> subscription.pending_setup_intent.client_secret
      end

    {:ok, client_secret}
  end
end
