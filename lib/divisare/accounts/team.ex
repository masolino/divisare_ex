defmodule Divisare.Accounts.Team do
  @moduledoc """
  Represents a team of subscribers.
  """

  use Ecto.Schema

  import Ecto.Query, warn: false

  # alias Divisare.Accounts.User

  schema "divisare_teams" do
    field(:name, :string)
    field(:email_domain, :string)
    field(:expire_on, :date)
    field(:members_limit, :integer)

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  def by_email_domain(query \\ __MODULE__, email_domain) do
    from(q in query, where: q.email_domain == ^email_domain)
  end

  def is_active(query \\ __MODULE__) do
    from(q in query, where: q.expire_on >= ^Date.utc_today())
  end
end
