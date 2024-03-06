defmodule Divisare.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DivisareWeb.Telemetry,
      # Start the Ecto repository
      Divisare.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Divisare.PubSub},
      # Start Finch
      {Finch, name: Divisare.Finch},
      # Start the Endpoint (http/https)
      DivisareWeb.Endpoint
      # Start a worker by calling: Divisare.Worker.start_link(arg)
      # {Divisare.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Divisare.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DivisareWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
