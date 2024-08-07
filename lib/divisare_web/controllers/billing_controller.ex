defmodule DivisareWeb.BillingController do
  use DivisareWeb, :controller

  alias Divisare.Subscriptions
  alias Divisare.Billings
  alias Divisare.Utils
  alias Divisare.Invoices

  require Logger

  plug DivisareWeb.Plugs.RequireUserAuthentication,
    not_logged_in_url: "#{Application.get_env(:divisare, :main_host)}/login"

  plug DivisareWeb.Plugs.RequireUserMembership
  plug DivisareWeb.Plugs.PageTitle, title: "VAT invoice"

  def info(conn, _) do
    with {:ok, billing} <- Billings.find_user_billing_info(conn.assigns.current_user_id) do
      message = invoicing_message(conn.assigns.current_user_id, billing)
      render(conn, :info, billing: billing, message: message)
    else
      {:error, :billing_not_found} ->
        changeset = Billings.Billing.new_changeset()
        assigns = form_assigns(changeset, [])
        render(conn, :new, assigns)

      _ ->
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def edit(conn, _) do
    with {:ok, billing} <- Billings.find_user_billing_info(conn.assigns.current_user_id) do
      changeset = Billings.Billing.new_changeset(billing)
      message = invoicing_message(conn.assigns.current_user_id, billing)
      assigns = form_assigns(changeset, []) |> Map.merge(%{message: message})
      render(conn, :edit, assigns)
    else
      {:error, :billing_not_found} ->
        changeset = Billings.Billing.new_changeset()
        assigns = form_assigns(changeset, [])
        render(conn, :edit, assigns)

      {:error, :user_not_found} ->
        redirect(conn, external: Application.get_env(:divisare, :main_host))
    end
  end

  def add(conn, %{"billing" => _} = params) do
    Billings.add_user_billing_info(conn.assigns.current_user, params)
    |> case do
      {:ok, billing} ->
        message = invoicing_message(conn.assigns.current_user_id, billing)
        render(conn, :info, billing: billing, message: message)

      {:error, %Ecto.Changeset{errors: errs} = changeset} ->
        errors = Enum.map(errs, fn {k, {e, _}} -> "#{k}: #{e}" end)
        assigns = form_assigns(changeset, errors)
        render(conn, :new, assigns)

      {:error, err} ->
        Logger.error(inspect(err))
        redirect(conn, to: ~p"/billing")
    end
  end

  def update(conn, %{"billing" => _} = params) do
    Billings.update_user_billing_info(conn.assigns.current_user, params)
    |> case do
      {:ok, billing} ->
        message = invoicing_message(conn.assigns.current_user_id, billing)
        render(conn, :info, billing: billing, message: message)

      {:error, %Ecto.Changeset{errors: errs} = changeset} ->
        errors = Enum.map(errs, fn {k, {e, _}} -> "#{k}: #{e}" end)
        assigns = form_assigns(changeset, errors)
        render(conn, :edit, assigns)

      {:error, err} ->
        Logger.error(inspect(err))
        redirect(conn, to: ~p"/billing")
    end
  end

  defp form_assigns(changeset, errors) do
    %{
      changeset: changeset,
      countries: Utils.Countries.eu_countries(),
      vies_countries: Utils.Countries.eu_countries_vies() |> Enum.into(%{}),
      subdivisions: Utils.Countries.eu_countries_subdivisions() |> Enum.into(%{}),
      errors: errors
    }
  end

  defp invoicing_message(user_id, billing) do
    {:ok, subscription} = Subscriptions.find_subscription_by_user_id(user_id)
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
