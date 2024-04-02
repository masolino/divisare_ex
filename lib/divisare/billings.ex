defmodule Divisare.Billings do
  @moduledoc """
  The Billings context.
  """

  alias Divisare.Billings.Billing
  alias Divisare.Repo

  def add_billing_info(%Divisare.Accounts.User{} = user, attrs) do
    params = Map.merge(attrs, %{"user_id" => user.id})

    Billing.changeset(params)
    |> Repo.insert()
  end
end
