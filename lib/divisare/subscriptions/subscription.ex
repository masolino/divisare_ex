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
    field(:stripe_id, :string, source: :token)
    field(:expire_on, :date)
    field(:amount, :decimal)

    # billing info
    field(:business, :boolean, default: false)
    field(:invoiced, :boolean, default: false)
    field(:address, :string)
    field(:vat_number, :string)
    field(:tax_rate, :decimal)
    field(:country_code, :string)
    field(:auto_renew, :boolean)

    field(:paid_at, :utc_datetime)

    belongs_to :user, Divisare.Accounts.User, foreign_key: :person_id, references: :id

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  @required_fields ~w(stripe_customer_id expire_on amount person_id)a
  @optional_fields ~w(business invoiced vat country_code tax_rate address paid_at auto_renew)a

  @doc false
  def changeset(%__MODULE__{} = subscription, attrs) do
    subscription
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> put_change(:auto_renew, true)
  end

  def changeset_cancel(%__MODULE__{} = subscription) do
    subscription
    |> cast(%{}, [])
    |> put_change(:expire_on, Date.utc_today())
    |> put_change(:auto_renew, false)
  end

  def by_customer_id(query \\ __MODULE__, customer_id) do
    from(q in query, where: q.stripe_customer_id == ^customer_id)
  end

  def by_most_recent(query \\ __MODULE__) do
    order_by(query, desc: :created_at)
  end

  def by_limit(query \\ __MODULE__, limit) do
    limit(query, ^limit)
  end
end
