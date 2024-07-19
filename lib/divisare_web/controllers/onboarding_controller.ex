defmodule DivisareWeb.OnboardingController do
  use DivisareWeb, :controller

  alias Divisare.Onboarding
  alias Divisare.Subscriptions

  require Logger

  plug :check_user_subscription when action in [:new]

  plug DivisareWeb.Plugs.PageTitle, title: "Subscribe"

  def new(conn, _params) do
    render(conn, :new, data: %{"email" => nil})
  end

  def create(conn, %{"email" => email, "price_id" => price_id, "name" => name}) do
    case Onboarding.get_stripe_subscription_client_secret(
           name,
           email,
           price_id,
           conn.assigns.current_user
         ) do
      {:ok, client_secret} -> json(conn, %{client_secret: client_secret})
      {:error, reason} -> conn |> put_status(:bad_request) |> json(%{error: reason})
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

  defp check_user_subscription(conn, _) do
    with {:user, user} when not is_nil(user) <- {:user, conn.assigns.current_user},
         {kind, sub} <- Subscriptions.guess_user_enrollment(user),
         true <- Subscriptions.check_user_enrollment_is_active({kind, sub}) do
      redirect(conn, to: ~p"/subscription")
    else
      _ -> conn
    end
  end
end
