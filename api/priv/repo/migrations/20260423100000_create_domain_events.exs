defmodule ZanshinApi.Repo.Migrations.CreateDomainEvents do
  use Ecto.Migration

  def change do
    create table(:domain_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_type, :string, null: false
      add :event_version, :integer, null: false, default: 1
      add :aggregate_type, :string, null: false
      add :aggregate_id, :binary_id, null: false
      add :occurred_at, :utc_datetime, null: false
      add :actor_role, :string
      add :payload, :map, null: false
      add :source, :string, null: false, default: "api"
      add :correlation_id, :string
      add :causation_id, :string
      add :processed_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:domain_events, [:aggregate_type, :aggregate_id])
    create index(:domain_events, [:event_type])
    create index(:domain_events, [:processed_at])
    create index(:domain_events, [:inserted_at])
  end
end
