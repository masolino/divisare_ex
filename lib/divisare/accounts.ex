defmodule Divisare.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Divisare.Accounts.User
  alias Divisare.Billings
  alias Divisare.Repo

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def update_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
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

  def add_billing_info(params) do
    # %{                                                                                                   16:24:07 [25/2889]
    #   "billing" => %{
    #     "address" => "Some street out there, 23",
    #     "business" => "true",
    #     "cf" => "XXXXXXXXXXXXXXXXXXXXX",
    #     "city" => "Rome",
    #     "country_code" => "IT",
    #     "heading" => "Some Company",
    #     "pec" => "some@pec.it",
    #     "postal_code" => "00192",
    #     "sdi" => "XXXXXXXXXXXX",
    #     "state_code" => "RM",
    #     "vat" => "XXXXXXXXXXXXXX"
    #   },
    #   "token" => "XXXXXXXXXXXXXXXXXXX",
    # }

    with {:ok, user} <- find_user_by_token(params["token"]),
         {:ok, _} <- Billings.add_user_billing_info(user, params["billing"]) do
      {:ok, user}
    else
      {:error, err} -> {:error, err}
    end
  end
end
