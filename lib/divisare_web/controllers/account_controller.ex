defmodule DivisareWeb.AccountController do
  use DivisareWeb, :controller

  alias Divisare.Accounts
  alias Divisare.Billings
  alias Divisare.Utils

  require Logger

  def billing(conn, params) do
    token = params["token"]

    with {:ok, user} <- Accounts.find_user_by_token(token),
         {:ok, billing} <- Billings.find_user_billing_info(user.id) do
      render(conn, :billing_info, billing: billing)
    else
      {:error, :billing_not_found} ->
        assigns = %{
          data: %{token: token},
          countries: Utils.Countries.all(),
          subdivisions: Utils.Countries.countries_subdivisions() |> Enum.into(%{}),
          eu_countries: Utils.Countries.by_region("Europe") |> Enum.map(&elem(&1, 1)),
          errors: []
        }

        render(conn, :billing_form, assigns)

      {:error, :user_not_found} ->
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def update_billing(conn, %{"token" => token} = params) do
    Accounts.add_billing_info(params)
    |> case do
      {:ok, _billing} ->
        render(conn, :billing_thanks, token: token)

      {:error, %Ecto.Changeset{errors: errs}} ->
        errors = Enum.map(errs, fn {k, {e, _}} -> "#{k}: #{e}" end)

        data = %{token: params["token"]}
        countries = Utils.Countries.all()
        subdivisions = Utils.Countries.countries_subdivisions() |> Enum.into(%{})
        eu_countries = Utils.Countries.by_region("Europe") |> Enum.map(&elem(&1, 1))

        render(conn, :billing_form,
          data: data,
          countries: countries,
          subdivisions: subdivisions,
          eu_countries: eu_countries,
          errors: errors
        )

      {:error, err} ->
        Logger.error(inspect(err))
        redirect(conn, to: ~p"/billing/#{params["token"]}")
    end
  end
end
