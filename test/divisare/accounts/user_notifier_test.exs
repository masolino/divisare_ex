defmodule Divisare.Accounts.UserNotifierTest do
  use ExUnit.Case, async: true
  import Swoosh.TestAssertions

  alias Divisare.Accounts.UserNotifier

  # test "deliver_welcome/1" do
  #   user = %{name: "Alice", email: "alice@example.com"}
  #
  #   UserNotifier.deliver_welcome(user)
  #
  #   assert_email_sent(
  #     subject: "Welcome to Divisare",
  #     to: {"Alice", "alice@example.com"},
  #     text_body: ~r/Hello, Alice/
  #   )
  # end
end
