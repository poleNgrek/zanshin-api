defmodule ZanshinApi.Repo.Migrations.CreateShinpanAssignments do
  use Ecto.Migration

  def change do
    create table(:shinpan_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tournament_id, references(:tournaments, type: :binary_id, on_delete: :delete_all), null: false
      add :shiaijo_id, references(:shiaijos, type: :binary_id, on_delete: :delete_all), null: false
      add :shinpan_id, references(:shinpans, type: :binary_id, on_delete: :delete_all), null: false
      add :match_id, references(:matches, type: :binary_id, on_delete: :nilify_all)
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false
      add :role, :string, null: false, default: "head"

      timestamps(type: :utc_datetime)
    end

    create index(:shinpan_assignments, [:tournament_id])
    create index(:shinpan_assignments, [:shinpan_id, :starts_at, :ends_at])
    create index(:shinpan_assignments, [:shiaijo_id, :starts_at, :ends_at])
    create index(:shinpan_assignments, [:match_id])
  end
end
