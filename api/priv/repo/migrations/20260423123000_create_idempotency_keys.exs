defmodule ZanshinApi.Repo.Migrations.CreateIdempotencyKeys do
  use Ecto.Migration

  def change do
    create table(:idempotency_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :endpoint, :string, null: false
      add :actor_subject, :string, null: false
      add :request_fingerprint, :string, null: false
      add :response_status, :integer
      add :response_body, :map
      add :completed_at, :utc_datetime
      add :last_replayed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:idempotency_keys, [:key, :endpoint, :actor_subject],
             name: :idempotency_keys_key_endpoint_actor_subject_index
           )

    create index(:idempotency_keys, [:completed_at])
    create index(:idempotency_keys, [:endpoint, :inserted_at])
  end
end
