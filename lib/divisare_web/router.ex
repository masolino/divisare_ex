defmodule DivisareWeb.Router do
  use DivisareWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {DivisareWeb.Layouts, :root}
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DivisareWeb.Plugs.PageTitle, title: "Divisare"
    plug DivisareWeb.Plugs.DeviseSession
    plug DivisareWeb.Plugs.AuthenticateUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DivisareWeb do
    pipe_through :browser

    get "/", HomeController, :index
    get "/onboarding", OnboardingController, :new
    post "/onboarding", OnboardingController, :create
    get "/onboarding/confirm", OnboardingController, :confirm

    get "/billing", BillingController, :info
    get "/billing/edit", BillingController, :edit
    post "/billing/", BillingController, :add
    put "/billing/", BillingController, :update

    get "/payments", PaymentController, :info
    get "/payments/complete", PaymentController, :complete

    get "/subscription/", SubscriptionController, :info
    post "/subscription/toggle", SubscriptionController, :toggle
  end

  # Other scopes may use custom stacks.
  # scope "/api", DivisareWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:divisare, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DivisareWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
