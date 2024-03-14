defmodule Divisare.Accounts.User do
  @moduledoc """
  Represents a user of the system.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  import DivisareWeb.Gettext

  import Divisare.Utils.Ecto

  alias Divisare.Utils.Passwords
  alias Divisare.Utils

  schema "people" do
    field(:email, :string)
    field(:name, :string)
    field(:admin, :boolean)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:encrypted_password, :string)
    field(:reset_password_token, :string)

    field(:confirmation_token, :string)
    field(:confirmed_at, :utc_datetime)

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  @required_fields ~w(email name)a
  @optional_fields ~w()a
  @password_fields ~w(password password_confirmation)a
  @password_reset_fields @password_fields ++ ~w(reset_password_token)a

  @doc false
  def changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @password_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> downcase_email
    |> validate_format(:email, Utils.email_regex())
    |> unsafe_validate_unique([:email], Divisare.Repo)
    |> apply_password_changes
  end

  @doc false
  def onboarding_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, Utils.email_regex())
    |> downcase_email
    |> unsafe_validate_unique([:email], Divisare.Repo)
    |> put_change(:admin, false)
    |> apply_devise_changes()
    |> apply_password_changes()
  end

  def password_reset_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @password_reset_fields)
    |> validate_required(@password_reset_fields)
    |> apply_password_changes()
  end

  defp apply_devise_changes(user_changeset) do
    pwd = Utils.random_string(16)

    user_changeset
    |> put_change(:password, pwd)
    |> put_change(:password_confirmation, pwd)
    |> put_change(:confirmation_token, Utils.random_string(32))
    |> put_change(:confirmed_at, Timex.now() |> DateTime.truncate(:second))
    |> generate_reset_password_token()
  end

  defp apply_password_changes(user_changeset) do
    user_changeset
    |> validate_length(:password, min: 6, max: 20)
    |> validate_length(:password_confirmation, min: 6, max: 20)
    |> validate_confirmation(:password, message: dgettext("errors", "does not match password"))
    |> hash_password
  end

  defp hash_password(user_changeset) do
    case user_changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        hashed_password = Passwords.hash_password(password)
        put_change(user_changeset, :encrypted_password, hashed_password)

      _ ->
        user_changeset
    end
  end

  defp generate_reset_password_token(user_changeset) do
    case user_changeset do
      %Ecto.Changeset{valid?: true} ->
        {_, password_token} = Passwords.generate_reset_password_token()
        put_change(user_changeset, :reset_password_token, password_token)

      _ ->
        user_changeset
    end
  end
end
