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
end
