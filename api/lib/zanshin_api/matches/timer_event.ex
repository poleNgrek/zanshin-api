defmodule ZanshinApi.Matches.TimerEvent do
  @moduledoc "Auditable timer command/event stream."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @commands [:start, :pause, :resume, :overtime]
  @statuses [:idle, :running, :paused, :overtime, :completed]
  @roles [:admin, :timekeeper, :shinpan]

  schema "timer_events" do
    field :command, Ecto.Enum, values: @commands
    field :from_status, Ecto.Enum, values: @statuses
    field :to_status, Ecto.Enum, values: @statuses
    field :elapsed_before_ms, :integer
    field :elapsed_after_ms, :integer
    field :occurred_at, :utc_datetime
    field :actor_role, Ecto.Enum, values: @roles
    field :metadata, :map, default: %{}

    belongs_to :timer, ZanshinApi.Matches.Timer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :timer_id,
      :command,
      :from_status,
      :to_status,
      :elapsed_before_ms,
      :elapsed_after_ms,
      :occurred_at,
      :actor_role,
      :metadata
    ])
    |> validate_required([
      :timer_id,
      :command,
      :from_status,
      :to_status,
      :elapsed_before_ms,
      :elapsed_after_ms,
      :occurred_at,
      :actor_role
    ])
    |> validate_number(:elapsed_before_ms, greater_than_or_equal_to: 0)
    |> validate_number(:elapsed_after_ms, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:timer_id)
  end
end
