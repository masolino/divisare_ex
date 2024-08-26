defmodule Divisare.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  alias Divisare.Accounts
  alias Divisare.Subscriptions.Subscription
  alias Divisare.Stripe, as: StripeService
  alias Divisare.Repo

  require Logger

  def find_or_create_subscription(%{stripe_customer_id: customer_id} = params) do
    customer_id
    |> Subscription.by_customer_id()
    |> Subscription.is_active()
    |> Repo.all()
    |> List.first()
    |> case do
      nil ->
        params = Map.merge(params, %{type: "ReaderSubscription"})

        %Subscription{}
        |> Subscription.changeset(params)
        |> Repo.insert()

      subscription ->
        {:ok, subscription}
    end
  end

  @doc """
  Renew a subscription.
  """
  def cycle_subscription(stripe_subscription_id, expiration_datetime) do
    expire_on = DateTime.to_date(expiration_datetime)

    Subscription.by_subscription_id(stripe_subscription_id)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :subscription_not_found}

      subscription ->
        subscription
        |> Subscription.changeset_cycle(expire_on)
        |> Repo.update()
    end
    |> case do
      {:ok, subscription} ->
        Logger.info("Stripe subscription: #{stripe_subscription_id} renewed")
        {:ok, subscription}

      {:error, err} ->
        Logger.error(
          "Stripe subscription: #{stripe_subscription_id} wasn't renewed: #{inspect(err)}"
        )

        {:error, err}
    end
  end

  @doc """
  Cancel a subscription which might even not started yet. Usually called for payments gone wrong.
  """
  def cancel_subscription(stripe_subscription_id) do
    Subscription.by_subscription_id(stripe_subscription_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :subscription_not_found}
      subscription -> subscription |> Subscription.changeset_cancel() |> Repo.update()
    end

    StripeService.cancel_stripe_subscription(stripe_subscription_id)
  end

  @doc """
  Toggle subscription auto-renew both on db and on Stripe service.
  """
  def toggle_subscription_auto_renew(user_id) do
    with {:ok, subscription} <- find_subscription_by_user_id(user_id),
         {:ok, updated} <- subscription |> Subscription.changeset_toggle() |> Repo.update(),
         {:ok, _} <-
           StripeService.toggle_subscription_auto_renew(
             updated.stripe_subscription_id,
             not updated.auto_renew
           ) do
      {:ok, updated}
    end
  end

  def find_subscription_by_user_id(user_id) do
    Subscription.by_user_id(user_id)
    |> Subscription.is_active()
    |> Repo.one()
    |> case do
      nil -> {:error, :subscription_not_found}
      subscription -> {:ok, subscription}
    end
  end

  def find_subscription_by_stripe_customer(customer_id) do
    Subscription.by_customer_id(customer_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :subscription_not_found}
      subscription -> {:ok, subscription}
    end
  end

  def guess_user_enrollment(user) do
    find_user_subscription(user)
  end

  def check_user_enrollment_is_active({:subscription, sub}) do
    case Date.compare(sub.expire_on, Date.utc_today()) do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  end

  def check_user_enrollment_is_active({:team, team}) do
    case Date.compare(team.expire_on, Date.utc_today()) do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  end

  def check_user_enrollment_is_active({:board, board}), do: board.status == :active
  def check_user_enrollment_is_active(_), do: false

  defp find_user_subscription(user) do
    case find_subscription_by_user_id(user.id) do
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
      _ -> {:error, :no_user_enrollment}
    end
  end
end
