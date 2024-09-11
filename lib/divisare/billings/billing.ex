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

  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

  def new_changeset(%__MODULE__{} = billing \\ %__MODULE__{}) do
    cast(billing, %{}, @required_fields ++ @optional_fields)
  end

  @doc false
  def changeset(%__MODULE__{} = billing \\ %__MODULE__{}, attrs) do
    billing
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> check_state_code()
    |> validate_required(@required_fields)
    |> validate_length(:heading,
      min: 3,
      max: 70,
      message: "invalid length (should be between 3 and 70 characters)"
    )
    |> validate_length(:address,
      min: 6,
      max: 255,
      message: "invalid length (should be between 6 and 255 characters)"
    )
    |> validate_length(:city,
      min: 3,
      max: 70,
      message: "invalid length (should be between 2 and 70 characters)"
    )
    |> validate_length(:postal_code,
      min: 2,
      max: 20,
      message: "invalid length (should be between 2 and 20 characters)"
    )
    |> apply_validations()
  end

  def by_user_id(query \\ __MODULE__, user_id) do
    from(q in query, where: q.user_id == ^user_id)
  end

  def latest(query \\ __MODULE__) do
    from(q in query, order_by: [desc: q.updated_at], limit: 1)
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

      true ->
        validate_vies_vat(changeset)
    end
  end

  defp validate_ita_vat(changeset) do
    changeset
    |> validate_required([:vat])
    |> validate_length(:vat, is: 13, message: "invalid length (must be 13 characters)")
  end

  defp validate_vies_vat(cs) do
    cs = put_change(cs, :business, true)

    vat = get_field(cs, :vat)
    country = get_field(cs, :country_code)
    {vat_country, vat_number} = String.split_at(vat, 2)

    with {:vat, true} <- {:vat, String.length(vat_number) > 0},
         {:country, true} <- {:country, vat_country == country},
         {:vies, true} <- {:vies, Viex.valid?(vat)} do
      cs
    else
      {:vat, false} -> add_error(cs, :vat, "required")
      {:country, false} -> add_error(cs, :vat, "is not a valid #{country} VAT number")
      {:vies, false} -> add_error(cs, :vat, "invalid VAT for VIES")
    end
  end

  defp validate_sdi(%Ecto.Changeset{changes: %{sdi_code: sdi_code}} = changeset)
       when not is_nil(sdi_code) do
    validate_length(changeset, :sdi_code,
      is: 7,
      message: "invalid length (must be 7 characters)"
    )
  end

  defp validate_sdi(changeset), do: changeset

  defp validate_cf(%Ecto.Changeset{changes: %{cf: cf}} = changeset) when not is_nil(cf) do
    if String.length(cf) == 16 or String.length(cf) == 11 do
      changeset
    else
      add_error(changeset, :cf, "invalid length (must be 11 or 16 characters)")
    end
  end

  defp validate_cf(changeset), do: validate_required(changeset, [:cf])

  defp validate_pec(%Ecto.Changeset{changes: %{pec: pec}} = changeset) when not is_nil(pec) do
    validate_format(changeset, :pec, @email_regex, message: "is invalid")
  end

  defp validate_pec(changeset), do: changeset

  defp is_ita_non_business(cs) do
    get_field(cs, :country_code) == "IT" and not get_field(cs, :business, false)
  end

  defp is_ita_business(cs) do
    get_field(cs, :country_code) == "IT" and get_field(cs, :business, false)
  end

  defp check_state_code(cs) do
    with {:country, country} when not is_nil(country) <-
           {:country, get_field(cs, :country_code, nil)},
         {:state, state} when not is_nil(state) <- {:state, get_field(cs, :state_code, nil)},
         state_codes <- get_country_state_codes(country),
         {:check, true} <- {:check, state in state_codes} do
      cs
    else
      {:country, _} -> put_change(cs, :state_code, nil)
      {:state, _} -> add_error(cs, :state_code, "can't be blank")
      {:check, false} -> add_error(cs, :state_code, "invalid")
    end
  end

  defp get_country_state_codes(country) do
    Divisare.Utils.Countries.eu_countries_subdivisions()
    |> Keyword.get(String.to_atom(country))
    |> Enum.map(fn c -> Map.keys(c) |> List.first() end)
  end
end
