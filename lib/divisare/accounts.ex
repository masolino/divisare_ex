defmodule Divisare.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Divisare.Accounts.User
  alias Divisare.Repo

  def find_or_onboard_user(email) do
    case Repo.get_by(User, email: email) do
      nil -> onboard_user(email)
      user -> {:ok, user}
    end
  end

  def onboard_user(email) do
    name = String.split(email, "@") |> List.first()
    params = %{email: email, name: name}

    %User{} |> User.onboarding_changeset(params) |> Repo.insert()
  end
end
