defmodule ZanshinApi.Repo.Migrations.CreateScoreEvents do
  use Ecto.Migration

  def change do
    create table(:score_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :match_id, references(:matches, type: :binary_id, on_delete: :delete_all), null: false
      add :score_type, :string, null: false
      add :side, :string, null: false
      add :actor_role, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:score_events, [:match_id])
    create index(:score_events, [:score_type])
    create index(:score_events, [:side])
  end
end
