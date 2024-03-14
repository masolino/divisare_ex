defmodule DivisareWeb.OnboardingHTML do
  use DivisareWeb, :html

  embed_templates "onboarding_html/*"

  @doc """
  Renders a onboarding form.
  """
  attr :data, :map, required: true
  attr :action, :string, required: true

  def onboarding_form(assigns)
end
