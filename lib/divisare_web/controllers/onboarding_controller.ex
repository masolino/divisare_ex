defmodule DivisareWeb.OnboardingController do
  use DivisareWeb, :controller

  alias Divisare.Onboarding
  alias Divisare.Subscriptions
  alias Divisare.Accounts

  require Logger

  plug :check_logged_user_subscription when action in [:new, :create]
  plug :check_existing_user_subscription when action in [:create]

  plug DivisareWeb.Plugs.PageTitle, title: "Subscribe"

  def new(conn, _params) do
    render(conn, :new, data: %{"email" => nil})
  end

  def create(conn, %{"email" => email, "price_id" => price_id, "name" => name}) do
    case Onboarding.get_stripe_subscription_client_secret(
           name,
           email,
           price_id,
           Map.get(conn.assigns, :current_user)
         ) do
      {:ok, client_secret} ->
        json(conn, %{client_secret: client_secret})

      {:error, reason} ->
        Logger.error("Error during onboarding: #{inspect(reason)}")
        conn |> put_status(:bad_request) |> json(%{error: inspect(reason)})
    end
  end

  def confirm(
        conn,
        %{
          "email" => email,
          "payment_intent" => payment_intent_id,
          "name" => name,
          "redirect_status" => status
        } = _params
      ) do
    case status do
      "failed" ->
        render(conn, :failed)

      _ ->
        {:ok, user, _subscription} = Onboarding.onboard_customer(name, email, payment_intent_id)
        render(conn, :confirm, user: user)
    end
  end

  defp check_logged_user_subscription(conn, _) do
    with {:user, user} when not is_nil(user) <- {:user, Map.get(conn.assigns, :current_user)},
         {kind, sub} when kind not in [:error] <- Subscriptions.guess_user_enrollment(user),
         true <- Subscriptions.check_user_enrollment_is_active({kind, sub}) do
      redirect(conn, to: ~p"/subscription")
    else
      _ -> conn
    end
  end

  defp check_existing_user_subscription(%{body_params: %{"email" => email}} = conn, _) do
    with {:user, {:ok, user}} <- {:user, Accounts.find_user_by_email(email)},
         {kind, sub} when kind not in [:error] <- Subscriptions.guess_user_enrollment(user),
         true <- Subscriptions.check_user_enrollment_is_active({kind, sub}) do
      json(conn, %{redirect: true}) |> halt
    else
      _ -> conn
    end
  end
end
