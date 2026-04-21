defmodule ZanshinApi.Teams.Team do
  @moduledoc "Team roster root for team-format divisions."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "teams" do
    field :name, :string

    belongs_to :division, ZanshinApi.Competitions.Division
    has_many :members, ZanshinApi.Teams.TeamMember

    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :division_id])
    |> validate_required([:name, :division_id])
    |> validate_length(:name, min: 2, max: 120)
    |> foreign_key_constraint(:division_id)
  end
end
