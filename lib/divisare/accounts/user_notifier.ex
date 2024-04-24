defmodule Divisare.Accounts.UserNotifier do
  import Swoosh.Email
  import Phoenix.Component

  alias Divisare.Mailer

  use Phoenix.VerifiedRoutes,
    endpoint: DivisareWeb.Endpoint,
    router: DivisareWeb.Router,
    statics: DivisareWeb.static_paths()

  defp email_layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <style>
        </style>
      </head>
      <body>
        <%= render_slot(@inner_block) %>
      </body>
    </html>
    """
  end

  defp welcome_content(assigns) do
    ~H"""
    <.email_layout>
      <h1>Welcome to Divisare!</h1>

      <p>
        Click on the link below to access your account page where you can set up your password for site access.
      </p>

      <p>
        From there, you can also check your subscription status, cancel automatic renewal,
        fill out your information to receive a receipt or invoice for payment,
        update or change your subscription method, or delete your account.
      </p>

      <a href={@url}><%= @url %></a>

      <p>We're here to help you with anything you need!</p>

      <p>Divisare team</p>
    </.email_layout>
    """
  end

  def deliver_welcome_email(user) do
    url =
      Application.get_env(:divisare, :main_host)
      |> URI.parse()
      |> URI.merge("/people/edit")
      |> to_string

    template = welcome_content(%{url: url})
    html = heex_to_html(template)
    text = html_to_text(html)

    Phoenix.Router

    email =
      new()
      |> to(user.email)
      |> from({"Divisare", "divisare@divisare.com"})
      |> subject("Welcome to Divisare")
      |> html_body(html)
      |> text_body(text)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp heex_to_html(template) do
    template
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp html_to_text(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("body")
    |> Floki.text(sep: "\n\n")
  end
end
