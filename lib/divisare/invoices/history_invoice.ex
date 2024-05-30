defmodule Divisare.Invoices.HistoryInvoice do
  @moduledoc """
  Represents the historycal invoice data.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Divisare.Accounts
  alias Divisare.Subscriptions

  schema "history_invoices" do
    field(:heading, :string)
    field(:address, :string)
    field(:postal_code, :string)
    field(:country_code, :string)
    field(:state_code, :string)
    field(:city, :string)
    field(:cf, :string)
    field(:pec, :string)
    field(:vat, :string)
    field(:sdi_code, :string)
    field(:business, :boolean)

    field(:stripe_customer_id, :string)
    field(:stripe_subscription_id, :string)
    field(:stripe_payment_method_id, :string)
    field(:paid_at, :utc_datetime)

    field(:invoiced_at, :utc_datetime)

    belongs_to(:user, Accounts.User, foreign_key: :user_id, references: :id)

    belongs_to(:subscription, Subscriptions.Subscription,
      foreign_key: :subscription_id,
      references: :id
    )

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(user_id subscription_id stripe_customer_id stripe_subscription_id  )a
  @optional_fields ~w(stripe_payment_method_id paid_at heading business address postal_code country_code state_code city cf pec vat sdi_code invoiced_at)a

  @doc false
  def changeset(%__MODULE__{} = hi \\ %__MODULE__{}, attrs) do
    hi
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def changeset_update(%__MODULE__{} = hi, attrs) do
    cast(hi, attrs, @optional_fields)
  end

  # Queries
  def by_stripe_subscription(query \\ __MODULE__, subscription_id) do
    from(q in query, where: q.stripe_subscription_id == ^subscription_id)
  end

  def by_user_id(query \\ __MODULE__, user_id) do
    from(q in query, where: q.user_id == ^user_id)
  end

  def is_latest(query \\ __MODULE__) do
    from(q in query, order_by: [desc: q.inserted_at], limit: 1)
  end

  def is_invoiced(query \\ __MODULE__, invoiced)
  def is_invoiced(query, false), do: from(q in query, where: is_nil(q.invoiced_at))
  def is_invoiced(query, true), do: from(q in query, where: not is_nil(q.invoiced_at))
end
