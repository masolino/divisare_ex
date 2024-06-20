defmodule Divisare.Onboarding do
  alias Divisare.Accounts
  alias Divisare.Subscriptions
  alias Divisare.Invoices
  alias Divisare.Stripe, as: StripeService
  alias Divisare.Accounts.UserNotifier

  alias Divisare.Repo

  def get_stripe_subscription_client_secret(name, email, price_id) do
    case StripeService.subscribe_customer(name, email, price_id) do
      {:ok, subscription} -> extract_client_secret_from_subscription(subscription)
      {:error, reason} -> {:error, reason}
    end
  end

  def onboard_customer(name, email, payment_intent_id) do
    with {:ok, payment_intent} = StripeService.get_payment_intent(payment_intent_id),
         {:ok, %Stripe.Invoice{subscription: stripe_subscription_id}} <-
           StripeService.get_invoice(payment_intent.invoice),
         true <- payment_intent.receipt_email == email,
         {:ok, is_new, user} <- find_or_onboard_user(name, email),
         {:ok, subscription} <-
           Subscriptions.find_or_create_subscription(%{
             payment_intent: payment_intent_id,
             email: email,
             person_id: user.id,
             expire_on: Date.utc_today() |> Timex.shift(years: 1),
             amount: Decimal.from_float(payment_intent.amount / 100),
             stripe_customer_id: payment_intent.customer,
             stripe_subscription_id: stripe_subscription_id,
             currency: payment_intent.currency
           }),
         {:ok, _history_invoice} <-
           insert_invoice_history(
             subscription.id,
             stripe_subscription_id,
             user.id,
             payment_intent.customer
           ),
         {:ok, _} <- send_welcome_email(is_new, user) do
      {:ok, user, subscription}
    else
      false -> {:error, "Receipt email does not match Stripe email"}
      {:error, error} -> error
    end
  end

  defp extract_client_secret_from_subscription(subscription) do
    client_secret =
      case Map.get(subscription, :pending_setup_intent) do
        nil -> subscription.latest_invoice.payment_intent.client_secret
        _ -> subscription.pending_setup_intent.client_secret
      end

    {:ok, client_secret}
  end

  defp send_welcome_email(false, _user), do: {:ok, nil}
  defp send_welcome_email(true, user), do: UserNotifier.deliver_welcome_email(user)

  defp find_or_onboard_user(name, email) do
    case Accounts.find_user_by_email(email) do
      {:error, _} -> onboard_user(name, email)
      {:ok, user} -> {:ok, false, user}
    end
  end

  defp onboard_user(name, email) do
    params = %{email: email, name: name}

    {:ok, user} = Accounts.User.onboarding_changeset(params) |> Repo.insert()
    {:ok, true, user}
  end

  # we need to create history invoice using as much data as possible
  # because webhook events are async and we can't guarantee the availability of all necessary data
  defp insert_invoice_history(
         subscription_id,
         stripe_subscription_id,
         user_id,
         stripe_customer_id
       ) do
    with {:ok, subscription} <- StripeService.get_subscription(stripe_subscription_id) do
      Invoices.create_history_invoice(%{
        user_id: user_id,
        subscription_id: subscription_id,
        stripe_customer_id: stripe_customer_id,
        stripe_subscription_id: stripe_subscription_id,
        stripe_payment_method_id: subscription.default_payment_method,
        paid_at: NaiveDateTime.utc_now()
      })
    end
  end
end