defmodule Divisare.Subscriptions.Subscription do
  @moduledoc """
  Represents a user of the system.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Divisare.Utils
  import Divisare.Utils.Ecto

  schema "divisare_subscriptions" do
    field(:stripe_customer_id, :string, source: :stripe_customer_token)
    field(:expire_on, :date)
    field(:amount, :decimal)

    # billing info
    field(:business, :boolean, default: false)
    field(:invoiced, :boolean, default: false)
    field(:address, :string)
    field(:vat, :string)
    field(:tax_rate, :decimal)
    field(:country_code, :string)

    field(:paid_at, :utc_datetime)

    belongs_to :user, Divisare.Accounts.User, foreign_key: :person_id, references: :id

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  @required_fields ~w(stripe_customer_id expire_on amount person_id)a
  @optional_fields ~w(business invoiced vat country_code tax_rate address paid_at)a

  @doc false
  def changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
