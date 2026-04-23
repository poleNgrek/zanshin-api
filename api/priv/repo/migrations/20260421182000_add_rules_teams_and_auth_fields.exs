defmodule ZanshinApi.Repo.Migrations.AddRulesTeamsAndAuthFields do
  use Ecto.Migration

  def change do
    alter table(:competitors) do
      add :birth_date, :date
    end

    alter table(:score_events) do
      add :target, :string
    end

    create table(:division_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :division_id, references(:divisions, type: :binary_id, on_delete: :delete_all), null: false
      add :category_type, :string, null: false, default: "open"
      add :age_group, :string, null: false, default: "open"
      add :min_age, :integer
      add :max_age, :integer
      add :match_duration_seconds, :integer, null: false, default: 300
      add :encho_mode, :string, null: false, default: "unlimited_sudden_death"
      add :encho_duration_seconds, :integer
      add :allow_tsuki, :boolean, null: false, default: true
      add :team_size, :integer, null: false, default: 5
      add :scoring_mode, :string, null: false, default: "match_wins_then_ippon"
      add :representative_match_enabled, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:division_rules, [:division_id])

    create table(:teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :division_id, references(:divisions, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:division_id])

    create table(:team_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, type: :binary_id, on_delete: :delete_all), null: false
      add :competitor_id, references(:competitors, type: :binary_id, on_delete: :restrict), null: false
      add :position, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:team_members, [:team_id])
    create unique_index(:team_members, [:team_id, :position])
    create unique_index(:team_members, [:team_id, :competitor_id])
  end
end
