defmodule Divisare.Services.Onboarding do
  alias Divisare.Accounts
  alias Divisare.Accounts.User
  alias Divisare.Subscriptions
  alias Divisare.Billings
  alias Divisare.Services.Stripe, as: StripeService
  alias Divisare.Accounts.UserNotifier

  alias Divisare.Repo

  def get_stripe_subscription_client_secret(email, price_id) do
    case StripeService.subscribe_customer(email, price_id) do
      {:ok, subscription} -> extract_client_secret_from_subscription(subscription)
      {:error, reason} -> {:error, reason}
    end
  end

  def onboard_customer(email, payment_intent_id) do
    with {:ok, payment_intent} = StripeService.get_payment_intent(payment_intent_id),
         true <- payment_intent.receipt_email == email,
         {:ok, is_new, user} <- find_or_onboard_user(email),
         {:ok, subscription} <-
           Subscriptions.find_or_create_subscription(%{
             payment_intent: payment_intent_id,
             email: email,
             person_id: user.id,
             expire_on: Date.utc_today() |> Timex.shift(years: 1),
             amount: Decimal.from_float(payment_intent.amount / 100),
             stripe_customer_id: payment_intent.customer,
             currency: payment_intent.currency
           }),
         {:ok, _} <- send_welcome_email(is_new, user) do
      {:ok, user, subscription}
    else
      false -> {:error, "Receipt email does not match Stripe email"}
      {:error, error} -> error
    end
  end

  def complete_user_profile(params) do
    # %{                                                                                                   16:24:07 [25/2889]
    #   "billing" => %{
    #     "address" => "Some street out there, 23",
    #     "business" => "true",
    #     "cf" => "XXXXXXXXXXXXXXXXXXXXX",
    #     "city" => "Rome",
    #     "country_code" => "IT",
    #     "heading" => "Some Company",
    #     "pec" => "some@pec.it",
    #     "postal_code" => "00192",
    #     "sdi" => "XXXXXXXXXXXX",
    #     "state_code" => "RM",
    #     "vat" => "XXXXXXXXXXXXXX"
    #   },
    #   "token" => "XXXXXXXXXXXXXXXXXXX",
    # }

    with {:ok, user} <-
           Accounts.find_user_by_password_reset_token(params["token"]),
         {:ok, _} <- Billings.add_billing_info(user, params["billing"]) do
      {:ok, user}
    else
      {:error, err} -> {:error, err}
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

  defp find_or_onboard_user(email) do
    case Accounts.find_user_by_email(email) do
      nil -> onboard_user(email)
      user -> {:ok, false, user}
    end
  end

  defp onboard_user(email) do
    name = String.split(email, "@") |> List.first()
    params = %{email: email, name: name}

    {:ok, user} = User.onboarding_changeset(params) |> Repo.insert()
    {:ok, true, user}
  end
end
