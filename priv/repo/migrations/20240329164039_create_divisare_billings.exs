defmodule Divisare.Repo.Migrations.CreateDivisareBillings do
  use Ecto.Migration

  def change do
    create table(:divisare_billings) do
      add(:heading, :string, null: false)
      add(:address, :string, null: false)
      add(:postal_code, :string, null: false)
      add(:country_code, :string, null: false)
      add(:state_code, :string, null: false)
      add(:city, :string, null: false)
      add(:user_id, :integer, null: false)

      add(:business, :boolean, default: false)
      add(:cf, :string)
      add(:pec, :string)
      add(:vat, :string)
      add(:sdi_code, :string)

      timestamps()
    end
  end
end
