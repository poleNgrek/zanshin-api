defmodule ZanshinApi.Repo.Migrations.CreateDivisionStages do
  use Ecto.Migration

  def change do
    create table(:division_stages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :division_id, references(:divisions, type: :binary_id, on_delete: :delete_all), null: false
      add :stage_type, :string, null: false
      add :sequence, :integer, null: false
      add :advances_count, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:division_stages, [:division_id])
    create unique_index(:division_stages, [:division_id, :sequence])
  end
end
