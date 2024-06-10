defmodule Divisare.Accounts.BoardMembership do
  @moduledoc """
  Represents a team of subscribers.
  """

  use Ecto.Schema

  import Ecto.Query, warn: false

  alias Divisare.Accounts.Board
  alias Divisare.Accounts.User

  @statuses ~w(waiting active suspended archived)a

  schema "divisare_board_members" do
    field :status, Ecto.Enum, values: [waiting: 0, active: 1, suspended: 2, archived: 3]

    belongs_to :user, User, foreign_key: :person_id, references: :id
    belongs_to :board, Board, foreign_key: :divisare_board_id, references: :id

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  def by_user(query \\ __MODULE__, user_id) do
    from(q in query, where: q.person_id == ^user_id)
  end

  def by_status(query \\ __MODULE__, status)

  def by_status(query, status) when status in @statuses do
    from(q in query, where: q.status == ^status)
  end

  def by_status(query, _status), do: query

  def preload_board(query \\ __MODULE__) do
    query
    |> join(:left, [q], s in assoc(q, :board))
    |> preload([q, b], board: b)
  end
end
