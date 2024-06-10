defmodule DivisareWeb.SubscriptionController do
  use DivisareWeb, :controller

  alias Divisare.Accounts
  alias Divisare.Subscriptions

  require Logger

  def info(conn, %{"token" => token} = _params) do
    {:ok, user} = Accounts.find_user_by_token(token)

    case find_user_enrollment(user) do
      #  redirect to home page?
      {:error, _} -> redirect(conn, to: ~p"/subscription/#{token}")
      enrollment -> render(conn, :info, token: token, enrollment: enrollment)
    end
  end

  def toggle(conn, %{"token" => token}) do
    with {:ok, _subscription} <- Subscriptions.toggle_subscription_auto_renew(token) do
      redirect(conn, to: ~p"/subscription/#{token}")
    else
      _ -> redirect(conn, to: ~p"/subscription/#{token}")
    end
  end

  def cancel(conn, %{"token" => token}) do
    with {:ok, _subscription} <- Subscriptions.interrupt_subscription(token) do
      redirect(conn, to: ~p"/subscription/#{token}")
    end
  end

  defp find_user_enrollment(user) do
    case find_user_subscription(user) do
      {:subscription, sub} -> {:subscription, sub}
      {:team, team} -> {:team, team}
      {:board, board} -> {:board, board}
    end
  end

  defp find_user_subscription(user) do
    case Subscriptions.find_subscription_by_user_token(user.token) do
      {:ok, sub} -> {:subscription, sub}
      _ -> find_user_team_membership(user)
    end
  end

  defp find_user_team_membership(user) do
    case Accounts.find_user_team_membership(user.email) do
      {:ok, team} -> {:team, team}
      _ -> find_user_board_membership(user)
    end
  end

  defp find_user_board_membership(user) do
    case Accounts.find_user_board_membership(user.id) do
      {:ok, board} -> {:board, board}
      _ -> find_user_board_membership(user)
    end
  end
end
