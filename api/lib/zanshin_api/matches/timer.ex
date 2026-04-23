defmodule ZanshinApi.Matches.Timer do
  @moduledoc "Authoritative match timer model."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses [:idle, :running, :paused, :overtime, :completed]

  schema "timers" do
    field :status, Ecto.Enum, values: @statuses, default: :idle
    field :elapsed_ms, :integer, default: 0
    field :run_started_at, :utc_datetime

    belongs_to :match, ZanshinApi.Matches.Match
    has_many :timer_events, ZanshinApi.Matches.TimerEvent

    timestamps(type: :utc_datetime)
  end

  def changeset(timer, attrs) do
    timer
    |> cast(attrs, [:status, :elapsed_ms, :run_started_at, :match_id])
    |> validate_required([:status, :elapsed_ms, :match_id])
    |> validate_number(:elapsed_ms, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:match_id)
    |> unique_constraint(:match_id)
  end
end
