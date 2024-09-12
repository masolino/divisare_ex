defmodule Divisare.Repo.Migrations.RemoveStripePaymentMethodIdFromHistoryInvoices do
  use Ecto.Migration

  def change do
    alter table(:history_invoices) do
      remove :stripe_payment_method_id
    end
  end
end
