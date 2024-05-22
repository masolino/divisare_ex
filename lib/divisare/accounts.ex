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
    case Repo.get_by(User, email: email) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  def find_user_by_token(token) do
    case Repo.get_by(User, token: token) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end
end
