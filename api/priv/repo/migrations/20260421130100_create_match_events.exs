defmodule ZanshinApi.Repo.Migrations.CreateMatchEvents do
  use Ecto.Migration

  def change do
    create table(:match_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :match_id, references(:matches, type: :binary_id, on_delete: :delete_all), null: false
      add :event, :string, null: false
      add :from_state, :string, null: false
      add :to_state, :string, null: false
      add :actor_role, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:match_events, [:match_id])
    create index(:match_events, [:event])
    create index(:match_events, [:actor_role])
  end
end
