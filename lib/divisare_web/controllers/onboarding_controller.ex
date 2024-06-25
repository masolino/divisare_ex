defmodule DivisareWeb.OnboardingController do
  use DivisareWeb, :controller

  alias Divisare.Onboarding

  require Logger

  def new(conn, _params) do
    render(conn, :new, data: %{"email" => nil})
  end

  def create(conn, %{"email" => email, "price_id" => price_id, "name" => name}) do
    case Onboarding.get_stripe_subscription_client_secret(name, email, price_id) do
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
    if status == "failed" do
      render(conn, :failed)
    else
      {:ok, user, _subscription} = Onboarding.onboard_customer(name, email, payment_intent_id)
      render(conn, :confirm, user: user)
    end
  end
end
