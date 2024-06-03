defmodule DivisareWeb.SubscriptionHTML do
  use DivisareWeb, :html

  embed_templates "subscription_html/*"

  use Phoenix.Component

  @doc """
  Renders a toggle subscription button.
  """

  attr :subscription, Divisare.Subscriptions.Subscription, required: true
  attr :token, :string, required: true

  def toggle_subscription_button(assigns) do
    ~H"""
    <div class="row">
      <div class="auto_renew">
        <div class="small-3 columns">
          <.simple_form
            :let={_f}
            for={%{}}
            action={~p"/subscription/#{@token}/toggle"}
            class="button_to"
            method="post"
          >
            <input
              data-confirm="Are you sure?"
              class="button secondary expand"
              type="submit"
              value={ "Turn " <> if @subscription.auto_renew, do: "OFF", else: "ON"  <> " Auto-Renew" }
            />
          </.simple_form>
        </div>
        <div class="small-4 columns end">
          If you turn off auto-renew now, you can still access your subscription until <%= Calendar.strftime(
            @subscription.expire_on,
            "%B %d, %Y"
          ) %>.
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders subscription status depending by the type of subscriber.
  """

  attr :subscription, Divisare.Subscriptions.Subscription, required: true

  def subscription_status(%{subscription: %{type: sub_type}} = assigns)
      when sub_type in [
             "EducationStudentSubscription",
             "EducationTeacherSubscription",
             "ReaderFriendSubscription"
           ] do
    sub_label =
      case sub_type do
        "EducationStudentSubscription" -> "Student"
        "EducationTeacherSubscription" -> "Teacher"
        "ReaderFriendSubscription" -> "Friend"
      end

    assigns = assign(assigns, :sub_label, sub_label)

    ~H"""
    <p>
      Your subscription <b>as <%= @sub_label %></b>
      is active until <%= Calendar.strftime(@subscription.expire_on, "%B %d, %Y") %>.
    </p>
    """
  end

  def subscription_status(%{subscription: %{type: "ReaderSubscription"}} = assigns) do
    ~H"""
    <p>
      Your subscription is active and will auto-renew on <%= Calendar.strftime(
        @subscription.expire_on,
        "%B %d, %Y"
      ) %>.
    </p>
    """
  end

  @doc """
  Renders a link to cancel the subscription.
  """

  attr :token, :string, required: true

  def cancel_subscription_link(assigns) do
    ~H"""
    <.link href={~p"/subscription/#{@token}/cancel"} method="put" data-confirm="Are you sure?">
      Cancel Your Subscription
    </.link>
    """
  end
end
