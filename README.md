# Divisare

This is a companion app for the main Divisare app which includes onboarding and payment of new users, plus some other features to complement the main app.

## Development environment

Follow these steps to start using it:

- ensure PostgreSQL containing the main Divisare db is running
- `mix setup` to install and setup dependencies
- `ìex -S mix phx.server` to start the local development server (please note that this command will also give you a _console_ to run Elixir commands while the app is running)

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Testing emails

Go to [`localhost:4000/dev/mailbox`](http://localhost:4000/dev/mailbox) and wait for emails to come (or refresh the page)
