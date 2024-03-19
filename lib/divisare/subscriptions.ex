defmodule Divisare.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  alias Divisare.Subscriptions.Subscription
  alias Divisare.Repo

  def create_subscription(params) do
    %Subscription{}
    |> Subscription.changeset(params)
    |> Repo.insert()
  end

  def cancel_subscription_by_customer_id(customer_id) do
    Subscription.by_customer_id(customer_id)
    |> Subscription.by_most_recent()
    |> Subscription.by_limit(1)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      subscription -> subscription |> Subscription.changeset_cancel() |> Repo.update()
    end
  end
end
