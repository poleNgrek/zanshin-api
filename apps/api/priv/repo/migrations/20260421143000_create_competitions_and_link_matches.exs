defmodule ZanshinApi.Repo.Migrations.CreateCompetitionsAndLinkMatches do
  use Ecto.Migration

  def change do
    create table(:tournaments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :location, :string
      add :starts_on, :date

      timestamps(type: :utc_datetime)
    end

    create table(:divisions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tournament_id, references(:tournaments, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :format, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:divisions, [:tournament_id])

    create table(:competitors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_name, :string, null: false
      add :federation_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:competitors, [:federation_id], where: "federation_id IS NOT NULL")

    execute("ALTER TABLE matches ALTER COLUMN tournament_id TYPE uuid USING tournament_id::uuid")
    execute("ALTER TABLE matches ALTER COLUMN division_id TYPE uuid USING division_id::uuid")
    execute("ALTER TABLE matches ALTER COLUMN aka_competitor_id TYPE uuid USING aka_competitor_id::uuid")
    execute("ALTER TABLE matches ALTER COLUMN shiro_competitor_id TYPE uuid USING shiro_competitor_id::uuid")

    alter table(:matches) do
      modify :tournament_id, references(:tournaments, type: :binary_id, on_delete: :restrict), null: false
      modify :division_id, references(:divisions, type: :binary_id, on_delete: :restrict), null: false
      modify :aka_competitor_id, references(:competitors, type: :binary_id, on_delete: :restrict), null: false
      modify :shiro_competitor_id, references(:competitors, type: :binary_id, on_delete: :restrict), null: false
    end
  end
end
