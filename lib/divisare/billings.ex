defmodule Divisare.Billings do
  @moduledoc """
  The Billings context.
  """

  alias Divisare.Billings.Billing
  alias Divisare.Repo

  def add_user_billing_info(%Divisare.Accounts.User{} = user, attrs) do
    params = Map.merge(attrs, %{"user_id" => user.id})

    Billing.changeset(params)
    |> Repo.insert()
  end

  def update_user_billing_info(%Divisare.Accounts.User{} = user, params) do
    with {:ok, billing} <- find_user_billing_info(user.id),
         {:ok, billing} <- Billing.changeset(billing, params) |> Repo.update() do
      {:ok, billing}
    else
      err -> err
    end
  end

  def find_user_billing_info(user_id) do
    case Repo.get_by(Billing, user_id: user_id) do
      nil -> {:error, :billing_not_found}
      billing -> {:ok, billing}
    end
  end
end
