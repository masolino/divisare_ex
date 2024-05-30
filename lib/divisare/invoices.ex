defmodule Divisare.Invoices do
  @moduledoc """
  The Subscriptions context.
  """

  alias Divisare.Invoices.HistoryInvoice
  alias Divisare.Repo

  def create_history_invoice(attrs) do
    attrs |> HistoryInvoice.changeset() |> Repo.insert()
  end

  def update_history_invoice_subscription(sub_id, attrs) do
    with {:ok, hi} <- find_history_invoice_by_stripe_subscription(sub_id) do
      HistoryInvoice.changeset_update(hi, attrs) |> Repo.update()
    end
  end

  def update_history_invoice_billing_data(user_id, attrs) do
    with {:ok, hi} <- find_history_invoice_by_user(user_id) do
      HistoryInvoice.changeset_update(hi, attrs) |> Repo.update()
    end
  end

  defp find_history_invoice_by_stripe_subscription(sub_id) do
    HistoryInvoice.by_stripe_subscription(sub_id)
    |> query_find_history_invoice
  end

  defp find_history_invoice_by_user(user_id) do
    HistoryInvoice.by_user_id(user_id)
    |> query_find_history_invoice()
  end

  defp query_find_history_invoice(query) do
    query
    |> HistoryInvoice.is_latest()
    |> HistoryInvoice.is_invoiced(false)
    |> Repo.one()
    |> case do
      nil -> {:error, :history_invoice_not_found}
      hi -> {:ok, hi}
    end
  end
end
