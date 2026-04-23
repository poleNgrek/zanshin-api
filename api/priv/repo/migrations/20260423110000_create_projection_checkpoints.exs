defmodule ZanshinApi.Repo.Migrations.CreateProjectionCheckpoints do
  use Ecto.Migration

  def change do
    create table(:projection_checkpoints, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :projection_name, :string, null: false
      add :last_event_id, :binary_id
      add :last_event_inserted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:projection_checkpoints, [:projection_name])
    create index(:projection_checkpoints, [:last_event_inserted_at])
  end
end
