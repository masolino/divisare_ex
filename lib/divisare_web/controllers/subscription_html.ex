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
  attr :token, :string, required: true

  def subscription_type(%{subscription: %{type: sub_type, expire_on: expiration_date}} = assigns)
      when sub_type in [
             "EducationStudentSubscription",
             "EducationTeacherSubscription"
           ] and not is_nil(expiration_date) do
    sub_label =
      case sub_type do
        "EducationStudentSubscription" -> "Student"
        "EducationTeacherSubscription" -> "Teacher"
      end

    assigns = assign(assigns, :sub_label, sub_label)

    if Timex.compare(expiration_date, Date.utc_today()) >= 0 do
      ~H"""
      <p>Your subscription allows you to have full access to divisare projects archive.</p>
      <p>
        Your subscription <b>as <%= @sub_label %></b>
        is active until <%= Calendar.strftime(@subscription.expire_on, "%B %d, %Y") %>.
      </p>
      """
    else
      ~H"""
      <.renew_expired_subscription link={
        URI.parse(
          "#{Application.get_env(:divisare, :main_host)}/subscription/academic/#{String.downcase(@sub_label)}/renew"
        )
      } />
      """
    end
  end

  def subscription_type(%{subscription: %{type: sub_type, expire_on: nil}} = assigns)
      when sub_type in [
             "EducationStudentSubscription",
             "EducationTeacherSubscription"
           ] do
    sub_label =
      case sub_type do
        "EducationStudentSubscription" -> "Student"
        "EducationTeacherSubscription" -> "Teacher"
      end

    assigns = assign(assigns, :sub_label, sub_label)

    ~H"""
    <h3>Your subscription as <%= @sub_label %> is awaiting activation.</h3>
    <p>Please check your email at <%= @subscription.academic_email %></p>
    """
  end

  def subscription_type(
        %{subscription: %{type: "ReaderFriendSubscription", expire_on: expiration_date}} = assigns
      ) do
    if Timex.compare(expiration_date, Date.utc_today()) >= 0 do
      assigns = assign(assigns, :sub_label, "Friend")

      ~H"""
      <p>Your subscription allows you to have full access to divisare projects archive.</p>
      <p>
        Your subscription <b>as <%= @sub_label %></b>
        is active until <%= Calendar.strftime(@subscription.expire_on, "%B %d, %Y") %>.
      </p>
      """
    else
      ~H"""
      <.renew_expired_subscription link={
        URI.parse("#{Application.get_env(:divisare, :main_host)}/subscriptions")
      } />
      """
    end
  end

  def subscription_type(
        %{subscription: %{type: "ReaderSubscription", expire_on: expiration_date}} = assigns
      ) do
    if Timex.compare(expiration_date, Date.utc_today()) >= 0 do
      ~H"""
      <p>Your subscription allows you to have full access to divisare projects archive.</p>
      <p>
        Your subscription is active and will <%= if @subscription.auto_renew,
          do: "auto-renew",
          else: "expire" %> on <%= Calendar.strftime(
          @subscription.expire_on,
          "%B %d, %Y"
        ) %>.
      </p>

      <.toggle_subscription_button subscription={@subscription} token={@token} />
      """
    else
      ~H"""
      <.renew_expired_subscription link={
        URI.parse("#{Application.get_env(:divisare, :main_host)}/subscriptions")
      } />
      """
    end
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

  @doc """
  Renders a button link to renew the subscription.
  """
  attr :link, :string, required: true

  def renew_expired_subscription(assigns) do
    ~H"""
    <h2>
      Your subscription
      expired on <%= Calendar.strftime(@subscription.expire_on, "%B %d, %Y") %>.
    </h2>

    <div class="row">
      <div class="small-12 medium-4 columns">
        <.link href={@link} class="button secondary expand">
          Renew your Subscription
        </.link>
      </div>
    </div>
    """
  end

  attr :enrollment, :any
  attr :token, :string

  def user_enrollment_type(assigns) do
    case assigns.enrollment do
      {:subscription, subscription} ->
        assigns = assign(assigns, :subscription, subscription)

        ~H"""
        <.subscription subscription={@subscription} token={@token} />
        """

      {:board, membership} ->
        assigns = assign(assigns, :membership, membership)

        ~H"""
        <.board membership={@membership} />
        """

      {:team, team} ->
        assigns = assign(assigns, :team, team)

        ~H"""
        <.team team={@team} />
        """
    end
  end
end
