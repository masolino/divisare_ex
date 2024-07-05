defmodule DivisareWeb.DivisareComponents do
  @moduledoc """
  Custom UI components.
  """
  use Phoenix.Component

  @doc """
  Renders Stripe JS tag.

  ## Examples

      <.stripe api_key={Application.get_env(:divisare, :stripe_publishable)}></.stripe>
  """
  attr :api_key, :string, required: true

  def stripe(assigns) do
    ~H"""
    <script src="https://js.stripe.com/v3/">
    </script>
    <span id="stripe-key" data-stripe={@api_key}></span>
    """
  end

  attr :page_title, :string, required: true

  def page_title(assigns) do
    page_title = assigns.page_title <> " · Divisare"
    assigns = assign(assigns, page_title: page_title)

    ~H"""
    <title><%= @page_title %></title>
    """
  end
end
