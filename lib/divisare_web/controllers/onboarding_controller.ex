defmodule DivisareWeb.OnboardingController do
  use DivisareWeb, :controller

  alias Divisare.Services.Onboarding

  def index(conn, _params) do
    render(conn, :new, data: %{"email" => nil})
  end

  def create(conn, params) do
    email = params["email"]
    price_id = params["price_id"]

    case Onboarding.get_stripe_subscription_client_secret(email, price_id) do
      {:ok, client_secret} -> json(conn, %{client_secret: client_secret})
      {:error, reason} -> conn |> put_status(:bad_request) |> json(%{error: reason})
    end
  end

  def confirm(conn, params) do
    email = params["email"]
    payment_intent_id = params["payment_intent"]
    status = params["status"]

    if status == "failed" do
      render(conn, :failed)
    else
      {:ok, _user, _subscription} = Onboarding.onboard_customer(email, payment_intent_id)
      render(conn, :confirm)
    end
  end
end
