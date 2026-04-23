defmodule ZanshinApi.Repo.Migrations.AddGradingDecisionAndLockFields do
  use Ecto.Migration

  def change do
    alter table(:grading_sessions) do
      add :required_pass_votes, :integer
    end

    alter table(:grading_results) do
      add :decision_snapshot, :map
      add :computed_at, :utc_datetime
      add :finalized_at, :utc_datetime
      add :locked_at, :utc_datetime
    end
  end
end
