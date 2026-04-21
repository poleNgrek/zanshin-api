defmodule ZanshinApi.Competitions.DivisionSpecialAward do
  @moduledoc """
  Special awards per division (for example fighting spirit).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @award_types [:fighting_spirit]

  schema "division_special_awards" do
    field :award_type, Ecto.Enum, values: @award_types

    belongs_to :division, ZanshinApi.Competitions.Division
    belongs_to :competitor, ZanshinApi.Competitions.Competitor
    belongs_to :team, ZanshinApi.Teams.Team

    timestamps(type: :utc_datetime)
  end

  def changeset(award, attrs) do
    award
    |> cast(attrs, [:division_id, :award_type, :competitor_id, :team_id])
    |> validate_required([:division_id, :award_type, :competitor_id])
    |> foreign_key_constraint(:division_id)
    |> foreign_key_constraint(:competitor_id)
    |> foreign_key_constraint(:team_id)
    |> unique_constraint([:division_id, :award_type],
      name: :division_special_awards_division_id_award_type_index
    )
  end
end
