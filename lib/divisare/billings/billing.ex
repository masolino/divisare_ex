defmodule Divisare.Billings.Billing do
  @moduledoc """
  Represents billing data for a user.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "divisare_billings" do
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

  @doc false
  def changeset(%__MODULE__{} = user \\ %__MODULE__{}, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> apply_validations()
  end

  defp apply_validations(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{business: false, country_code: "IT"}} ->
        changeset
        |> validate_required([:cf], message: "is required")

      %Ecto.Changeset{valid?: true, changes: %{business: true, country_code: "IT"}} ->
        changeset
        |> validate_required([:vat], message: "is required")
        |> validate_required_inclusion([:pec, :sdi_code])
        |> validate_ita_vat()

      %Ecto.Changeset{valid?: true, changes: %{business: true, country_code: cd}} when cd in @eu_countries and cd != "IT" ->
        changeset
        |> validate_required([:vat], message: "is required")
        |> validate_vies_vat()

      _ ->
        changeset
    end
  end

  defp validate_ita_vat(%Ecto.Changeset{changes: %{vat: vat}} = changeset) do
    if String.length(vat) == 11 do
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

  defp validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  defp present?(changeset, field) do
    value = get_field(changeset, field)
    value && value != ""
  end
end
