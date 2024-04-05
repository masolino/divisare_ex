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
    <script src="https://js.stripe.com/v3/"></script>
    <span id="stripe-key" data-stripe={@api_key}></span>
    """
  end
end
