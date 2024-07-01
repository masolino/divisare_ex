defmodule Divisare.Invoices do
  @moduledoc """
  The Subscriptions context.
  """

  alias Divisare.Billings
  alias Divisare.Invoices.HistoryInvoice
  alias Divisare.Repo

  @doc """
  Retrieve latest history invoice regardless if it has either been invoiced or not.
  """
  def get_user_current_history_invoice(user_id) do
    HistoryInvoice.by_user_id(user_id)
    |> HistoryInvoice.is_latest()
    |> Repo.one()
    |> case do
      nil -> {:error, :history_invoice_not_found}
      hi -> {:ok, hi}
    end
  end

  @doc """
  Adds a new history invoice based on the previous one and the actual billing info. This is used when a subscription is renewed.
  """
  def add_history_invoice(sub_id) do
    with {:ok, hi} <- find_history_invoice_by_stripe_subscription(sub_id),
         {:ok, billing} <- Billings.find_user_billing_info(hi.user_id) do
      history_invoice =
        Map.from_keys(
          ~w[heading address postal_code country_code state_code city cf pec vat sdi_code business
            stripe_customer_id stripe_subscription_id stripe_payment_method_id paid_at subscription_id user_id]a,
          hi
        )

      billing =
        Map.from_keys(
          ~w[heading address postal_code country_code state_code city business cf pec vat sdi_code]a,
          billing
        )

      Map.merge(history_invoice, billing)
      |> HistoryInvoice.changeset()
      |> Repo.insert()
    end
  end

  @doc """
  Creates a new history invoice from scratch. This is used when a new subscription is created.
  """
  def create_history_invoice(attrs) do
    attrs |> HistoryInvoice.changeset() |> Repo.insert()
  end

  @doc """
  Removes an history invoice. This is used when a subscription has been cancelled and the invoice hasn't been emitted yet.
  """
  def remove_history_invoice_subscription(sub_id) do
    with {:ok, hi} <- find_history_invoice_by_stripe_subscription(sub_id) do
      Repo.delete(hi)
    end
  end

  @doc """
  Updates an history invoice with the billing data. This is used when the billing data is updated but the invoice hasn't been emitted yet.
  """
  def update_history_invoice_billing_data(user_id, attrs) do
    with {:ok, hi} <- find_history_invoice_by_user(user_id) do
      HistoryInvoice.changeset_update(hi, attrs) |> Repo.update()
    end
  end

  defp find_history_invoice_by_stripe_subscription(sub_id) do
    HistoryInvoice.by_stripe_subscription(sub_id)
    |> query_find_history_invoice(false)
  end

  defp find_history_invoice_by_user(user_id) do
    HistoryInvoice.by_user_id(user_id)
    |> query_find_history_invoice(false)
  end

  defp query_find_history_invoice(query, is_invoiced) do
    query
    |> HistoryInvoice.is_latest()
    |> HistoryInvoice.is_invoiced(is_invoiced)
    |> Repo.one()
    |> case do
      nil -> {:error, :history_invoice_not_found}
      hi -> {:ok, hi}
    end
  end
end
