defmodule Divisare.Repo.Migrations.CreateHistoryInvoices do
  use Ecto.Migration

  def change do
    create table(:history_invoices) do
      add(:user_id, :integer, null: false)
      add(:subscription_id, :integer, null: false)
      add(:stripe_customer_id, :string, null: false)
      add(:stripe_subscription_id, :string, null: false)

      add(:stripe_payment_method_id, :string)
      add(:paid_at, :utc_datetime)
      add(:invoiced_at, :utc_datetime)

      add(:heading, :string)
      add(:address, :string)
      add(:postal_code, :string)
      add(:country_code, :string)
      add(:state_code, :string)
      add(:city, :string)
      add(:business, :boolean, default: false)
      add(:cf, :string)
      add(:pec, :string)
      add(:vat, :string)
      add(:sdi_code, :string)

      timestamps()
    end
  end
end
