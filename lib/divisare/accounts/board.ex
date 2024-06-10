defmodule Divisare.Accounts.Board do
  @moduledoc """
  Represents a team of subscribers.
  """

  use Ecto.Schema

  import Ecto.Query, warn: false

  alias Divisare.Accounts.User

  schema "divisare_boards" do
    field(:name, :string)
    field(:email, :string)
    field(:country_code, :string)
    field(:active, :boolean)

    has_many :users, {"divisare_board_members", User}

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  def is_active(query \\ __MODULE__) do
    from(q in query, where: q.active)
  end
end
