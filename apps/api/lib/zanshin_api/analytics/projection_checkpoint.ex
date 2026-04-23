defmodule ZanshinApi.Analytics.ProjectionCheckpoint do
  @moduledoc """
  Tracks the last successfully projected domain event per projection worker.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "projection_checkpoints" do
    field :projection_name, :string
    field :last_event_id, Ecto.UUID
    field :last_event_inserted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(checkpoint, attrs) do
    checkpoint
    |> cast(attrs, [:projection_name, :last_event_id, :last_event_inserted_at])
    |> validate_required([:projection_name])
    |> validate_length(:projection_name, min: 3, max: 120)
  end
end
