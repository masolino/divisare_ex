defmodule Divisare.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Divisare.Accounts.BoardMembership
  alias Divisare.Accounts.User
  alias Divisare.Accounts.Team
  alias Divisare.Repo

  def find_user_team_membership(user_email) do
    email_domain = String.split(user_email, "@") |> List.last()

    case Team.by_email_domain(email_domain) |> Repo.one() do
      nil -> {:error, :team_not_found}
      team -> {:ok, team}
    end
  end

  def find_user_board_membership(user_id) do
    BoardMembership.by_user(user_id)
    |> BoardMembership.preload_board()
    |> Repo.one()
    |> case do
      nil -> {:error, :board_not_found}
      board -> {:ok, board}
    end
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

  def find_user_by_id(id) do
    case Repo.get_by(User, id: id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end
end
