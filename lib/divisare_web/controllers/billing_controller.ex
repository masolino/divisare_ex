defmodule DivisareWeb.BillingController do
  use DivisareWeb, :controller

  alias Divisare.Accounts
  alias Divisare.Billings
  alias Divisare.Utils

  require Logger

  def info(conn, %{"token" => token}) do
    with {:ok, user} <- Accounts.find_user_by_token(token),
         {:ok, billing} <- Billings.find_user_billing_info(user.id) do
      render(conn, :info, billing: billing, token: token)
    else
      {:error, :billing_not_found} ->
        changeset = Billings.Billing.new_changeset()
        assigns = form_assigns(changeset, token, [])
        render(conn, :new, assigns)

      {:error, :user_not_found} ->
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def edit(conn, %{"token" => token}) do
    with {:ok, user} <- Accounts.find_user_by_token(token),
         {:ok, billing} <- Billings.find_user_billing_info(user.id) do
      changeset = Billings.Billing.new_changeset(billing)
      assigns = form_assigns(changeset, token, [])
      render(conn, :edit, assigns)
    else
      {:error, :billing_not_found} ->
        changeset = Billings.Billing.new_changeset()
        assigns = form_assigns(changeset, token, [])
        render(conn, :edit, assigns)

      {:error, :user_not_found} ->
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def add(conn, %{"billing" => _, "token" => token} = params) do
    Billings.add_user_billing_info(params)
    |> case do
      {:ok, billing} ->
        render(conn, :info, billing: billing, token: token)

      {:error, %Ecto.Changeset{errors: errs} = changeset} ->
        errors = Enum.map(errs, fn {k, {e, _}} -> "#{k}: #{e}" end)
        assigns = form_assigns(changeset, token, errors)
        render(conn, :new, assigns)

      {:error, err} ->
        Logger.error(inspect(err))
        redirect(conn, to: ~p"/billing/#{token}")
    end
  end

  def update(conn, %{"billing" => _, "token" => token} = params) do
    Billings.update_user_billing_info(params)
    |> case do
      {:ok, billing} ->
        render(conn, :info, billing: billing, token: token)

      {:error, %Ecto.Changeset{errors: errs} = changeset} ->
        errors = Enum.map(errs, fn {k, {e, _}} -> "#{k}: #{e}" end)
        assigns = form_assigns(changeset, token, errors)
        render(conn, :edit, assigns)

      {:error, err} ->
        Logger.error(inspect(err))
        redirect(conn, to: ~p"/billing/#{token}")
    end
  end

  defp form_assigns(changeset, token, errors) do
    %{
      changeset: changeset,
      data: %{token: token},
      countries: Utils.Countries.all(),
      subdivisions: Utils.Countries.countries_subdivisions() |> Enum.into(%{}),
      errors: errors
    }
  end
end
