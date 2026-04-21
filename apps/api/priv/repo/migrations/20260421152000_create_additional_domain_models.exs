defmodule ZanshinApi.Repo.Migrations.CreateAdditionalDomainModels do
  use Ecto.Migration

  def change do
    create table(:shinpans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_name, :string, null: false
      add :federation_id, :string
      add :tournament_id, references(:tournaments, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:shinpans, [:federation_id], where: "federation_id IS NOT NULL")
    create index(:shinpans, [:tournament_id])

    create table(:shiaijos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :tournament_id, references(:tournaments, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:shiaijos, [:tournament_id])

    create table(:timers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, null: false, default: "idle"
      add :elapsed_ms, :bigint, null: false, default: 0
      add :match_id, references(:matches, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:timers, [:match_id])

    create table(:grading_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :held_on, :date
      add :tournament_id, references(:tournaments, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:grading_sessions, [:tournament_id])

    create table(:grading_results, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :grade, :string, null: false
      add :passed, :boolean, null: false, default: false
      add :grading_session_id, references(:grading_sessions, type: :binary_id, on_delete: :delete_all),
        null: false
      add :competitor_id, references(:competitors, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:grading_results, [:grading_session_id])
    create index(:grading_results, [:competitor_id])
  end
end
