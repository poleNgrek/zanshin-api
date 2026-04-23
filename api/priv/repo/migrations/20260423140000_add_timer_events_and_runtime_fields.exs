defmodule ZanshinApi.Repo.Migrations.AddTimerEventsAndRuntimeFields do
  use Ecto.Migration

  def change do
    alter table(:timers) do
      add :run_started_at, :utc_datetime
    end

    create table(:timer_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :timer_id, references(:timers, type: :binary_id, on_delete: :delete_all), null: false
      add :command, :string, null: false
      add :from_status, :string, null: false
      add :to_status, :string, null: false
      add :elapsed_before_ms, :bigint, null: false
      add :elapsed_after_ms, :bigint, null: false
      add :occurred_at, :utc_datetime, null: false
      add :actor_role, :string, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:timer_events, [:timer_id, :inserted_at])
  end
end
