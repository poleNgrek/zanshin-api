defmodule ZanshinApi.Idempotency.RequestKey do
  @moduledoc """
  Tracks idempotent command request lifecycle and replay payloads.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "idempotency_keys" do
    field :key, :string
    field :endpoint, :string
    field :actor_subject, :string
    field :request_fingerprint, :string
    field :response_status, :integer
    field :response_body, :map
    field :completed_at, :utc_datetime
    field :last_replayed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def create_changeset(record, attrs) do
    record
    |> cast(attrs, [:key, :endpoint, :actor_subject, :request_fingerprint])
    |> validate_required([:key, :endpoint, :actor_subject, :request_fingerprint])
    |> validate_length(:key, min: 8, max: 200)
    |> validate_length(:endpoint, min: 3, max: 200)
    |> validate_length(:actor_subject, min: 1, max: 255)
    |> validate_length(:request_fingerprint, is: 64)
    |> unique_constraint([:key, :endpoint, :actor_subject],
      name: :idempotency_keys_key_endpoint_actor_subject_index
    )
  end

  def complete_changeset(record, attrs) do
    record
    |> cast(attrs, [:response_status, :response_body, :completed_at])
    |> validate_required([:response_status, :response_body, :completed_at])
    |> validate_number(:response_status, greater_than_or_equal_to: 100, less_than: 600)
  end

  def replayed_changeset(record) do
    change(record, %{last_replayed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
  end
end
