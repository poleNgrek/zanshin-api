defmodule ZanshinApi.Repo.Migrations.CreateBracketGraphModels do
  use Ecto.Migration

  def change do
    create table(:bracket_rounds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :division_id, references(:divisions, type: :binary_id, on_delete: :delete_all), null: false
      add :round_number, :integer, null: false
      add :label, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bracket_rounds, [:division_id, :round_number])
    create index(:bracket_rounds, [:division_id])

    create table(:bracket_slots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :round_id, references(:bracket_rounds, type: :binary_id, on_delete: :delete_all), null: false
      add :slot_number, :integer, null: false
      add :match_id, references(:matches, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bracket_slots, [:round_id, :slot_number])
    create index(:bracket_slots, [:round_id])

    create table(:bracket_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :from_slot_id, references(:bracket_slots, type: :binary_id, on_delete: :delete_all), null: false
      add :to_slot_id, references(:bracket_slots, type: :binary_id, on_delete: :delete_all), null: false
      add :outcome, :string, null: false, default: "winner"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bracket_links, [:from_slot_id, :to_slot_id, :outcome])
    create index(:bracket_links, [:to_slot_id])
  end
end
