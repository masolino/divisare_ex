defmodule Divisare.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  alias Divisare.Subscriptions.Subscription
  alias Divisare.Stripe, as: StripeService
  alias Divisare.Repo

  def find_or_create_subscription(%{stripe_customer_id: customer_id} = params) do
    customer_id
    |> Subscription.by_customer_id()
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
  def toggle_subscription_auto_renew(token) do
    with {:ok, subscription} <- find_subscription_by_user_token(token),
         {:ok, updated} <- subscription |> Subscription.changeset_toggle() |> Repo.update(),
         {:ok, _} <-
           StripeService.toggle_subscription_auto_renew(
             updated.stripe_subscription_id,
             not updated.auto_renew
           ) do
      {:ok, updated}
    end
  end

  @doc """
  Cancel a subscription which is already started. Usually called by subscriber.
  """
  def interrupt_subscription(token) do
    with {:ok, subscription} <- find_subscription_by_user_token(token),
         {:ok, updated} <- subscription |> Subscription.changeset_cancel() |> Repo.update(),
         {:ok, _} <- StripeService.cancel_stripe_subscription(updated.stripe_subscription_id) do
      {:ok, updated}
    end
  end

  def find_subscription_by_user_token(user_token) do
    Subscription.by_user_token(user_token)
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
end
