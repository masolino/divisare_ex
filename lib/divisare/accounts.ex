defmodule Divisare.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Divisare.Accounts.User
  alias Divisare.Repo

  def find_or_onboard_user(email) do
    case Repo.get_by(User, email: email) do
      nil -> onboard_user(email)
      user -> {:ok, false, user}
    end
  end

  def onboard_user(email) do
    name = String.split(email, "@") |> List.first()
    params = %{email: email, name: name}

    {:ok, user} = %User{} |> User.onboarding_changeset(params) |> Repo.insert()
    {:ok, true, user}
  end


  def find_user_by_password_reset_token(token) do
    case Repo.get_by(User, reset_password_token: token) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
