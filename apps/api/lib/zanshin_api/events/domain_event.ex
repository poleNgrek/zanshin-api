defmodule ZanshinApi.Events.DomainEvent do
  @moduledoc """
  Canonical domain event envelope persisted for outbox-style projections.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "domain_events" do
    field :event_type, :string
    field :event_version, :integer, default: 1
    field :aggregate_type, :string
    field :aggregate_id, Ecto.UUID
    field :occurred_at, :utc_datetime
    field :actor_role, :string
    field :payload, :map
    field :source, :string, default: "api"
    field :correlation_id, :string
    field :causation_id, :string
    field :processed_at, :utc_datetime

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_type,
      :event_version,
      :aggregate_type,
      :aggregate_id,
      :occurred_at,
      :actor_role,
      :payload,
      :source,
      :correlation_id,
      :causation_id,
      :processed_at
    ])
    |> validate_required([
      :event_type,
      :event_version,
      :aggregate_type,
      :aggregate_id,
      :occurred_at,
      :payload,
      :source
    ])
    |> validate_number(:event_version, greater_than: 0)
    |> validate_length(:event_type, min: 3, max: 120)
    |> validate_length(:aggregate_type, min: 3, max: 80)
    |> validate_length(:source, min: 2, max: 80)
  end
end
