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
      render(conn, :billing_info, billing: billing, token: token)
    else
      {:error, :billing_not_found} ->
        changeset = Billings.Billing.new_changeset()
        assigns = billing_form_assigns(changeset, token, [])
        render(conn, :billing_new, assigns)

      {:error, :user_not_found} ->
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def edit_billing(conn, params) do
    token = params["token"]

    with {:ok, user} <- Accounts.find_user_by_token(token),
         {:ok, billing} <- Billings.find_user_billing_info(user.id) do
      changeset = Billings.Billing.new_changeset(billing)
      assigns = billing_form_assigns(changeset, token, [])
      render(conn, :billing_edit, assigns)
    else
      {:error, :billing_not_found} ->
        changeset = Billings.Billing.new_changeset()
        assigns = billing_form_assigns(changeset, token, [])
        render(conn, :billing_edit, assigns)

      {:error, :user_not_found} ->
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def add_billing(conn, %{"billing" => _, "token" => token} = params) do
    Accounts.add_billing_info(params)
    |> case do
      {:ok, _billing} ->
        render(conn, :billing_thanks, token: token)

      {:error, %Ecto.Changeset{errors: errs} = changeset} ->
        errors = Enum.map(errs, fn {k, {e, _}} -> "#{k}: #{e}" end)
        assigns = billing_form_assigns(changeset, token, errors)
        render(conn, :billing_new, assigns)

      {:error, err} ->
        Logger.error(inspect(err))
        redirect(conn, to: ~p"/billing/#{params["token"]}")
    end
  end

  def update_billing(conn, %{"billing" => _, "token" => token} = params) do
    Accounts.update_billing_info(params)
    |> case do
      {:ok, billing} ->
        render(conn, :billing_info, billing: billing)

      {:error, %Ecto.Changeset{errors: errs} = changeset} ->
        errors = Enum.map(errs, fn {k, {e, _}} -> "#{k}: #{e}" end)
        assigns = billing_form_assigns(changeset, token, errors)
        render(conn, :billing_edit, assigns)

      {:error, err} ->
        Logger.error(inspect(err))
        redirect(conn, to: ~p"/billing/#{params["token"]}")
    end
  end

  def payment_method(conn, %{"token" => token} = _params) do
    render(conn, :payment_method, token: token)
  end

  defp billing_form_assigns(changeset, token, errors) do
    %{
      changeset: changeset,
      data: %{token: token},
      countries: Utils.Countries.all(),
      subdivisions: Utils.Countries.countries_subdivisions() |> Enum.into(%{}),
      eu_countries: Utils.Countries.by_region("Europe") |> Enum.map(&elem(&1, 1)),
      errors: errors
    }
  end
end
