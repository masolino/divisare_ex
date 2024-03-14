defmodule Divisare.Utils.Ecto do
  import Ecto.Changeset

  def downcase_email(changeset) do
    case changeset do
      %Ecto.Changeset{changes: %{email: email}} ->
        put_change(changeset, :email, String.downcase(email))

      _ ->
        changeset
    end
  end
end
