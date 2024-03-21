defmodule DivisareWeb.OnboardingController do
  use DivisareWeb, :controller

  alias Divisare.Services.Onboarding
  alias Divisare.Accounts

  def index(conn, _params) do
    render(conn, :new, data: %{"email" => nil})
  end

  def edit(conn, params) do
    token = params["token"]
    data = %{password: "", password_confirmation: "", password_reset_token: token, vat: nil}

    Accounts.find_user_by_password_reset_token(token)
    |> case do
      {:ok, _} -> render(conn, :edit, data: data)
      {:error, :not_found} -> redirect(conn, to: ~p"/onboarding")
    end
  end

  def create(conn, params) do
    email = params["email"]
    price_id = params["price_id"]

    case Onboarding.get_stripe_subscription_client_secret(email, price_id) do
      {:ok, client_secret} -> json(conn, %{client_secret: client_secret})
      {:error, reason} -> conn |> put_status(:bad_request) |> json(%{error: reason})
    end
  end

  def update(conn, params) do
    email = params["email"]
    vat = params["vat"]
    
    # TODO: store data to complete the user, and redirect to home page (possibly authenticated)
    Accounts.complete_user_profile(params)
    |> case do
      {:ok, _} -> redirect(conn, to: ~p"/onboarding/confirm/#{email}")
      {:error, _} -> redirect(conn, to: ~p"/onboarding/edit/#{conn.assigns.current_user.reset_password_token}")
    end

  end

  def confirm(conn, params) do
    email = params["email"]
    payment_intent_id = params["payment_intent"]
    status = params["status"]

    if status == "failed" do
      render(conn, :failed)
    else
      {:ok, user, _subscription} = Onboarding.onboard_customer(email, payment_intent_id)
      render(conn, :confirm, user: user)
    end
  end
end
