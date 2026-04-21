defmodule ZanshinApi.Teams.TeamMatch do
  @moduledoc "Team-vs-team match aggregate with optional daihyo-sen tie-break."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @states [:scheduled, :completed]

  schema "team_matches" do
    field :state, Ecto.Enum, values: @states, default: :scheduled
    field :team_a_wins, :integer, default: 0
    field :team_b_wins, :integer, default: 0
    field :team_a_ippon, :integer, default: 0
    field :team_b_ippon, :integer, default: 0
    field :representative_match_required, :boolean, default: false

    belongs_to :division, ZanshinApi.Competitions.Division
    belongs_to :team_a, ZanshinApi.Teams.Team
    belongs_to :team_b, ZanshinApi.Teams.Team
    belongs_to :winner_team, ZanshinApi.Teams.Team
    belongs_to :loser_team, ZanshinApi.Teams.Team
    belongs_to :representative_winner_team, ZanshinApi.Teams.Team

    timestamps(type: :utc_datetime)
  end

  def changeset(match, attrs) do
    match
    |> cast(attrs, [
      :division_id,
      :team_a_id,
      :team_b_id,
      :state,
      :team_a_wins,
      :team_b_wins,
      :team_a_ippon,
      :team_b_ippon,
      :representative_match_required,
      :representative_winner_team_id,
      :winner_team_id,
      :loser_team_id
    ])
    |> validate_required([:division_id, :team_a_id, :team_b_id, :state])
    |> validate_number(:team_a_wins, greater_than_or_equal_to: 0)
    |> validate_number(:team_b_wins, greater_than_or_equal_to: 0)
    |> validate_number(:team_a_ippon, greater_than_or_equal_to: 0)
    |> validate_number(:team_b_ippon, greater_than_or_equal_to: 0)
    |> validate_distinct_teams()
    |> validate_outcome_consistency()
    |> foreign_key_constraint(:division_id)
    |> foreign_key_constraint(:team_a_id)
    |> foreign_key_constraint(:team_b_id)
    |> foreign_key_constraint(:winner_team_id)
    |> foreign_key_constraint(:loser_team_id)
    |> foreign_key_constraint(:representative_winner_team_id)
  end

  defp validate_distinct_teams(changeset) do
    a = get_field(changeset, :team_a_id)
    b = get_field(changeset, :team_b_id)

    if a && b && a == b do
      add_error(changeset, :team_b_id, "must be different from team_a")
    else
      changeset
    end
  end

  defp validate_outcome_consistency(changeset) do
    state = get_field(changeset, :state)
    rep_required = get_field(changeset, :representative_match_required)
    rep_winner = get_field(changeset, :representative_winner_team_id)
    a_wins = get_field(changeset, :team_a_wins) || 0
    b_wins = get_field(changeset, :team_b_wins) || 0

    cond do
      state != :completed ->
        changeset

      rep_required and is_nil(rep_winner) ->
        add_error(
          changeset,
          :representative_winner_team_id,
          "is required when representative match is used"
        )

      rep_required and a_wins != b_wins ->
        add_error(changeset, :team_b_wins, "must tie when representative match is used")

      not rep_required and a_wins == b_wins ->
        add_error(changeset, :team_b_wins, "cannot tie without representative match")

      true ->
        changeset
    end
  end
end
