defmodule ZanshinApi.Matches.MatchEvent do
  @moduledoc """
  Audit trail for state transitions and match lifecycle actions.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @events [:prepare, :start, :pause, :resume, :complete, :verify, :cancel]
  @roles [:admin, :timekeeper, :shinpan]

  schema "match_events" do
    field :event, Ecto.Enum, values: @events
    field :from_state, Ecto.Enum, values: [:scheduled, :ready, :ongoing, :paused, :completed, :verified]
    field :to_state, Ecto.Enum, values: [:scheduled, :ready, :ongoing, :paused, :completed, :verified]
    field :actor_role, Ecto.Enum, values: @roles

    belongs_to :match, ZanshinApi.Matches.Match

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @required_fields ~w(match_id event from_state to_state actor_role)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:match_id)
  end
end
