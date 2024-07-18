defmodule Divisare.Billings do
  @moduledoc """
  The Billings context.
  """

  alias Divisare.Billings.Billing
  alias Divisare.Accounts
  alias Divisare.Invoices
  alias Divisare.Repo

  def add_user_billing_info(user, params) do
    with billing_params <- Map.merge(params["billing"], %{"user_id" => user.id}),
         {:ok, billing} <- Billing.changeset(billing_params) |> Repo.insert() do
      # NOTE: this returns ok UNLESS already invoiced. We'll just ignore the error otherwise.
      # (At this stage, we SHOULDN'T have any invoiced yet, but that's not 100% granted)
      Invoices.update_history_invoice_billing_data(user.id, Map.from_struct(billing))
      {:ok, billing}
    else
      {:error, err} -> {:error, err}
    end
  end

  def update_user_billing_info(user, params) do
    with {:ok, billing} <- find_user_billing_info(user.id),
         {:ok, billing} <- Billing.changeset(billing, params["billing"]) |> Repo.update() do
      # NOTE: this returns ok UNLESS already invoiced. We'll just ignore the error otherwise.
      Invoices.update_history_invoice_billing_data(user.id, Map.from_struct(billing))
      {:ok, billing}
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
