defmodule Divisare.Accounts.UserNotifier do
  import Swoosh.Email
  import Phoenix.Template

  alias DivisareWeb.EmailHTML
  alias Divisare.Mailer

  use Phoenix.VerifiedRoutes,
    endpoint: DivisareWeb.Endpoint,
    router: DivisareWeb.Router,
    statics: DivisareWeb.static_paths()

  def deliver_welcome_email(user) do
    url = url(~p"/subscription/")

    email =
      new()
      |> to(user.email)
      |> from({"Divisare", "divisare@divisare.com"})
      |> subject("Welcome to Divisare")
      |> render_body(:welcome, %{url: url})

    case Mailer.deliver(email) do
      {:ok, _} -> {:ok, email}
      {:error, _} = error -> error
    end
  end

  defp render_body(email, template, assigns) do
    html_heex = apply(EmailHTML, String.to_atom("#{template}_html"), [assigns])

    html =
      render_to_string(DivisareWeb.Layouts, "email", "html",
        email: email,
        inner_content: html_heex
      )

    email |> html_body(html)
  end
end
