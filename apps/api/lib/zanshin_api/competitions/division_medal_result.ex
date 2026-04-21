defmodule ZanshinApi.Competitions.DivisionMedalResult do
  @moduledoc """
  Medal podium entries per division.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @medals [:gold, :silver, :bronze]

  schema "division_medal_results" do
    field :place, :integer
    field :medal, Ecto.Enum, values: @medals

    belongs_to :division, ZanshinApi.Competitions.Division
    belongs_to :competitor, ZanshinApi.Competitions.Competitor
    belongs_to :team, ZanshinApi.Teams.Team

    timestamps(type: :utc_datetime)
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [:division_id, :place, :medal, :competitor_id, :team_id])
    |> validate_required([:division_id, :place, :medal])
    |> validate_inclusion(:place, [1, 2, 3])
    |> foreign_key_constraint(:division_id)
    |> foreign_key_constraint(:competitor_id)
    |> foreign_key_constraint(:team_id)
    |> unique_constraint([:division_id, :competitor_id],
      name: :division_medal_results_division_id_competitor_id_index
    )
    |> unique_constraint([:division_id, :team_id],
      name: :division_medal_results_division_id_team_id_index
    )
  end
end
