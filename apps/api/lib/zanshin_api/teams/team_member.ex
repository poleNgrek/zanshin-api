defmodule ZanshinApi.Teams.TeamMember do
  @moduledoc "Ordered competitor assignment in a team lineup."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @positions [:senpo, :jiho, :chuken, :fukusho, :taisho]

  schema "team_members" do
    field :position, Ecto.Enum, values: @positions

    belongs_to :team, ZanshinApi.Teams.Team
    belongs_to :competitor, ZanshinApi.Competitions.Competitor

    timestamps(type: :utc_datetime)
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:team_id, :competitor_id, :position])
    |> validate_required([:team_id, :competitor_id, :position])
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:competitor_id)
    |> unique_constraint([:team_id, :position], name: :team_members_team_id_position_index)
    |> unique_constraint([:team_id, :competitor_id],
      name: :team_members_team_id_competitor_id_index
    )
  end
end
