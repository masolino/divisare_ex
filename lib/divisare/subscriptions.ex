defmodule Divisare.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  alias Divisare.Subscriptions.Subscription
  alias Divisare.Repo

  def find_or_create_subscription(%{payment_intent: payment_intent_id} = params) do
    payment_intent_id
    |> Subscription.by_payment_intent()
    |> Repo.all()
    |> List.first()
    |> case do
      nil -> 
        %Subscription{}
        |> Subscription.changeset(params)
        |> Repo.insert()
      subscription -> {:ok, subscription}
    end
  end

  def cancel_subscription_by_customer_id(customer_id) do
    Subscription.by_customer_id(customer_id)
    |> Subscription.by_most_recent()
    |> Subscription.limit_by(1)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      subscription -> subscription |> Subscription.changeset_cancel() |> Repo.update()
    end
  end
end
