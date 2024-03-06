defmodule Divisare.Repo do
  use Ecto.Repo,
    otp_app: :divisare,
    adapter: Ecto.Adapters.Postgres
end
