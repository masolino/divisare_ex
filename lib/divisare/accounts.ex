defmodule Divisare.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Divisare.Accounts.User
  alias Divisare.Billings
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

  def add_billing_info(params) do
    with {:ok, user} <- find_user_by_token(params["token"]),
         {:ok, billing} <- Billings.add_user_billing_info(user, params["billing"]) do
      {:ok, billing}
    else
      {:error, err} -> {:error, err}
    end
  end

  def update_billing_info(params) do
    with {:ok, user} <- find_user_by_token(params["token"]),
         {:ok, billing} <- Billings.update_user_billing_info(user, params["billing"]) do
      {:ok, billing}
    else
      {:error, err} -> {:error, err}
    end
  end
end
