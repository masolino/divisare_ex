defmodule DivisareWeb.BillingController do
  use DivisareWeb, :controller

  alias Divisare.Subscriptions
  alias Divisare.Accounts
  alias Divisare.Billings
  alias Divisare.Utils
  alias Divisare.Invoices

  require Logger

  plug DivisareWeb.Plugs.RequireUserMembership
  plug DivisareWeb.Plugs.PageTitle, title: "VAT invoice"

  def info(conn, %{"token" => token}) do
    with {:ok, user} <- Accounts.find_user_by_token(token),
         {:ok, billing} <- Billings.find_user_billing_info(user.id) do
      message = invoicing_message(user.id, billing, token)
      render(conn, :info, billing: billing, token: token, message: message)
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
      countries: Utils.Countries.eu_countries(),
      vies_countries: Utils.Countries.eu_countries_vies() |> Enum.into(%{}),
      subdivisions: Utils.Countries.eu_countries_subdivisions() |> Enum.into(%{}),
      errors: errors
    }
  end

  defp invoicing_message(user_id, billing, token) do
    {:ok, subscription} = Subscriptions.find_subscription_by_user_token(token)
    {:ok, invoice} = Invoices.get_user_current_history_invoice(user_id)

    build_invoice_message(subscription, invoice, billing)
  end

  defp build_invoice_message(subscription, %{invoiced_at: nil}, billing) do
    subscription_date_limit = DateTime.add(subscription.created_at, 12, :day)
    diff = Timex.Comparable.diff(subscription_date_limit, billing.inserted_at, :days)

    cond do
      diff >= 0 ->
        "Please allow 3-5 business days to process your request."

      diff < 0 ->
        "Your subscription was paid more than 12 days ago. This information will be used for your next invoice (if any)."
    end
  end

  defp build_invoice_message(_, %{invoiced_at: invoiced_at}, _) do
    "The invoice was sent on #{Calendar.strftime(invoiced_at, "%B %d, %Y")}, this information will be used for the next invoice (if any)."
  end
end
