defmodule Divisare.Billings.Billing do
  @moduledoc """
  Represents billing data for a user.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "billing_informations" do
    field(:heading, :string)
    field(:address, :string)
    field(:postal_code, :string)
    field(:country_code, :string)
    field(:state_code, :string)
    field(:city, :string)

    field(:business, :boolean)
    field(:cf, :string)
    field(:pec, :string)
    field(:vat, :string)
    field(:sdi_code, :string)

    belongs_to(:user, Divisare.Accounts.User, foreign_key: :user_id, references: :id)

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(user_id heading address postal_code country_code state_code city)a
  @optional_fields ~w(business cf pec vat sdi_code)a

  @eu_countries Divisare.Utils.Countries.by_region("Europe") |> Enum.map(fn {_, v} -> v end)

  def new_changeset(%__MODULE__{} = billing \\ %__MODULE__{}) do
    cast(billing, %{}, @required_fields ++ @optional_fields)
  end

  @doc false
  def changeset(%__MODULE__{} = billing \\ %__MODULE__{}, attrs) do
    billing
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> apply_validations()
  end

  defp apply_validations(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{business: false, country_code: "IT"}} ->
        changeset
        |> validate_required([:cf], message: "is required")
        |> validate_cf_length

      %Ecto.Changeset{valid?: true, changes: %{business: true, country_code: "IT"}} ->
        changeset
        |> validate_required([:vat], message: "is required")
        |> validate_ita_vat()
        |> validate_sdi_length

      %Ecto.Changeset{valid?: true, changes: %{business: true, country_code: cd}}
      when cd in @eu_countries and cd != "IT" ->
        changeset
        |> validate_required([:vat], message: "is required")
        |> validate_vies_vat()

      _ ->
        changeset
    end
  end

  defp validate_ita_vat(%Ecto.Changeset{changes: %{vat: vat}} = changeset) do
    if String.length(vat) == 13 do
      changeset
    else
      add_error(changeset, :vat, "invalid")
    end
  end

  defp validate_ita_vat(changeset), do: add_error(changeset, :vat, "invalid")

  defp validate_vies_vat(%Ecto.Changeset{changes: %{vat: vat}} = changeset) do
    if Viex.valid?(vat) do
      changeset
    else
      add_error(changeset, :vat, "invalid")
    end
  end

  defp validate_vies_vat(changeset), do: add_error(changeset, :vat, "invalid")

  defp validate_sdi_length(changeset) do
    with sdi_code when not is_nil(sdi_code) <- get_field(changeset, :sdi_code),
         true <- String.length(sdi_code) == 7 do
      changeset
    else
      nil -> changeset
      false -> add_error(changeset, :sdi_code, "invalid length")
    end
  end

  defp validate_cf_length(changeset) do
    with cf when not is_nil(cf) <- get_field(changeset, :cf),
         true <- String.length(cf) == 16 or String.length(cf) == 11 do
      changeset
    else
      nil -> changeset
      false -> add_error(changeset, :cf, "invalid length")
    end
  end
end
