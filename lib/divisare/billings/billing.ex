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

  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

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
    cond do
      is_ita_non_business(changeset) ->
        validate_cf(changeset)

      is_ita_business(changeset) ->
        changeset
        |> validate_pec()
        |> validate_ita_vat()
        |> validate_sdi()

      is_eu_business(changeset) ->
        validate_vies_vat(changeset)

      true ->
        changeset
    end
  end

  defp validate_ita_vat(changeset) do
    changeset
    |> validate_required([:vat])
    |> validate_length(:vat, is: 13)
  end

  defp validate_vies_vat(%Ecto.Changeset{changes: %{vat: vat}} = changeset)
       when not is_nil(vat) do
    if Viex.valid?(vat) do
      changeset
    else
      add_error(changeset, :vat, "invalid")
    end
  end

  defp validate_vies_vat(changeset), do: validate_required(changeset, [:vat])

  defp validate_sdi(%Ecto.Changeset{changes: %{sdi_code: sdi_code}} = changeset)
       when not is_nil(sdi_code) do
    validate_length(changeset, :sdi_code, is: 7)
  end

  defp validate_sdi(changeset), do: changeset

  defp validate_cf(%Ecto.Changeset{changes: %{cf: cf}} = changeset) when not is_nil(cf) do
    if String.length(cf) == 16 or String.length(cf) == 11 do
      changeset
    else
      add_error(changeset, :cf, "invalid length")
    end
  end

  defp validate_cf(changeset), do: validate_required(changeset, [:cf])

  defp validate_pec(%Ecto.Changeset{changes: %{pec: pec}} = changeset) when not is_nil(pec) do
    validate_format(changeset, :pec, @email_regex)
  end

  defp validate_pec(changeset), do: changeset

  defp is_ita_non_business(cs) do
    get_field(cs, :country_code) == "IT" and not get_field(cs, :business, false)
  end

  defp is_ita_business(cs) do
    get_field(cs, :country_code) == "IT" and get_field(cs, :business, false)
  end

  defp is_eu_business(cs) do
    country = get_field(cs, :country_code)
    get_field(cs, :business, false) and country in @eu_countries and country != "IT"
  end
end
