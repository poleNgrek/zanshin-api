defmodule ZanshinApi.Repo.Migrations.CreateDivisionResultsAndAwards do
  use Ecto.Migration

  def change do
    create table(:division_medal_results, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :division_id, references(:divisions, type: :binary_id, on_delete: :delete_all), null: false
      add :place, :integer, null: false
      add :medal, :string, null: false
      add :competitor_id, references(:competitors, type: :binary_id, on_delete: :nilify_all)
      add :team_id, references(:teams, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:division_medal_results, [:division_id])
    create index(:division_medal_results, [:division_id, :place])
    create unique_index(:division_medal_results, [:division_id, :competitor_id])
    create unique_index(:division_medal_results, [:division_id, :team_id])

    create table(:division_special_awards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :division_id, references(:divisions, type: :binary_id, on_delete: :delete_all), null: false
      add :award_type, :string, null: false
      add :competitor_id, references(:competitors, type: :binary_id, on_delete: :nilify_all), null: false
      add :team_id, references(:teams, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:division_special_awards, [:division_id])
    create unique_index(:division_special_awards, [:division_id, :award_type])
  end
end
