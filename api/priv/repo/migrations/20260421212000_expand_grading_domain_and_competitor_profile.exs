defmodule ZanshinApi.Repo.Migrations.ExpandGradingDomainAndCompetitorProfile do
  use Ecto.Migration

  def change do
    alter table(:competitors) do
      add :preferred_stance, :string
      add :grade_value, :integer
      add :grade_type, :string
      add :grade_title, :string, default: "none"
    end

    alter table(:grading_sessions) do
      add :written_required, :boolean, null: false, default: true
      add :kata_carryover_months, :integer, null: false, default: 12
      add :written_carryover_months, :integer, null: false, default: 12
    end

    alter table(:grading_results) do
      add :target_grade, :string
      add :final_result, :string, null: false, default: "pending"
      add :jitsugi_result, :string, null: false, default: "not_attempted"
      add :kata_result, :string, null: false, default: "not_attempted"
      add :written_result, :string, null: false, default: "not_attempted"
      add :carryover_until, :date
      add :declared_stance, :string
    end

    execute("UPDATE grading_results SET target_grade = grade WHERE target_grade IS NULL")
    execute("UPDATE grading_results SET final_result = CASE WHEN passed THEN 'pass' ELSE 'fail' END")

    create table(:grading_examiners, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_name, :string, null: false
      add :federation_id, :string
      add :federation_name, :string
      add :grade, :string
      add :title, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:grading_examiners, [:federation_id], where: "federation_id IS NOT NULL")

    create table(:grading_panel_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :grading_session_id, references(:grading_sessions, type: :binary_id, on_delete: :delete_all),
        null: false

      add :examiner_id, references(:grading_examiners, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:grading_panel_assignments, [:grading_session_id, :examiner_id])

    create table(:grading_votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :grading_result_id, references(:grading_results, type: :binary_id, on_delete: :delete_all), null: false
      add :examiner_id, references(:grading_examiners, type: :binary_id, on_delete: :delete_all), null: false
      add :part, :string, null: false
      add :decision, :string, null: false
      add :note, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:grading_votes, [:grading_result_id, :examiner_id, :part])

    create table(:grading_notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :grading_result_id, references(:grading_results, type: :binary_id, on_delete: :delete_all), null: false
      add :examiner_id, references(:grading_examiners, type: :binary_id, on_delete: :delete_all), null: false
      add :part, :string
      add :note, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:grading_notes, [:grading_result_id])
  end
end
