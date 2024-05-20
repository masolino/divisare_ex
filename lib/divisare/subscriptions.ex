defmodule Divisare.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  alias Divisare.Subscriptions.Subscription
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

  def cancel_subscription(subscription_id) do
    Subscription.by_subscription_id(subscription_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      subscription -> subscription |> Subscription.changeset_cancel() |> Repo.update()
    end
  end
end
