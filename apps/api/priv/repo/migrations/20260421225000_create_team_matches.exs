defmodule ZanshinApi.Repo.Migrations.CreateTeamMatches do
  use Ecto.Migration

  def change do
    create table(:team_matches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :division_id, references(:divisions, type: :binary_id, on_delete: :delete_all), null: false
      add :team_a_id, references(:teams, type: :binary_id, on_delete: :delete_all), null: false
      add :team_b_id, references(:teams, type: :binary_id, on_delete: :delete_all), null: false
      add :state, :string, null: false, default: "scheduled"
      add :team_a_wins, :integer, null: false, default: 0
      add :team_b_wins, :integer, null: false, default: 0
      add :team_a_ippon, :integer, null: false, default: 0
      add :team_b_ippon, :integer, null: false, default: 0
      add :representative_match_required, :boolean, null: false, default: false
      add :representative_winner_team_id, references(:teams, type: :binary_id, on_delete: :nilify_all)
      add :winner_team_id, references(:teams, type: :binary_id, on_delete: :nilify_all)
      add :loser_team_id, references(:teams, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:team_matches, [:division_id])
    create index(:team_matches, [:winner_team_id])
  end
end
