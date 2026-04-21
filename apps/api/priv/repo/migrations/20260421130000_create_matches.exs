defmodule ZanshinApi.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tournament_id, :string, null: false
      add :division_id, :string, null: false
      add :aka_competitor_id, :string, null: false
      add :shiro_competitor_id, :string, null: false
      add :state, :string, null: false, default: "scheduled"

      timestamps(type: :utc_datetime)
    end

    create index(:matches, [:tournament_id])
    create index(:matches, [:division_id])
    create index(:matches, [:state])
  end
end
