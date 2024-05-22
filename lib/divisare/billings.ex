defmodule Divisare.Billings do
  @moduledoc """
  The Billings context.
  """

  alias Divisare.Billings.Billing
  alias Divisare.Accounts
  alias Divisare.Repo

  def add_user_billing_info(params) do
    with {:ok, user} <- Accounts.find_user_by_token(params["token"]) do
      billing_params = Map.merge(params["billing"], %{"user_id" => user.id})

      Billing.changeset(billing_params) |> Repo.insert()
    else
      {:error, err} -> {:error, err}
    end
  end

  def update_user_billing_info(params) do
    with {:ok, user} <- Accounts.find_user_by_token(params["token"]),
         {:ok, billing} <- find_user_billing_info(user.id) do
      Billing.changeset(billing, params["billing"]) |> Repo.update()
    else
      {:error, err} -> {:error, err}
    end
  end

  def find_user_billing_info(user_id) do
    case Repo.get_by(Billing, user_id: user_id) do
      nil -> {:error, :billing_not_found}
      billing -> {:ok, billing}
    end
  end
end
