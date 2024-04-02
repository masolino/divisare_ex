defmodule Divisare.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Divisare.Accounts.User
  alias Divisare.Repo


  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def update_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  def find_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def find_user_by_password_reset_token(token) do
    case Repo.get_by(User, reset_password_token: token) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
