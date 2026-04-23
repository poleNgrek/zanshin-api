defmodule ZanshinApi.Matches.Match do
  @moduledoc """
  Match aggregate root for lifecycle state transitions.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @states [:scheduled, :ready, :ongoing, :paused, :completed, :verified]

  schema "matches" do
    belongs_to :tournament, ZanshinApi.Competitions.Tournament
    belongs_to :division, ZanshinApi.Competitions.Division
    belongs_to :aka_competitor, ZanshinApi.Competitions.Competitor
    belongs_to :shiro_competitor, ZanshinApi.Competitions.Competitor
    field :state, Ecto.Enum, values: @states, default: :scheduled
    has_many :match_events, ZanshinApi.Matches.MatchEvent
    has_many :score_events, ZanshinApi.Matches.ScoreEvent
    has_one :timer, ZanshinApi.Matches.Timer

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(tournament_id division_id aka_competitor_id shiro_competitor_id)a
  @optional_fields ~w(state)a

  def create_changeset(match, attrs) do
    match
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_competitor_distinct()
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:division_id)
    |> foreign_key_constraint(:aka_competitor_id)
    |> foreign_key_constraint(:shiro_competitor_id)
  end

  def transition_changeset(match, attrs) do
    match
    |> cast(attrs, [:state])
    |> validate_required([:state])
  end

  defp validate_competitor_distinct(changeset) do
    aka = get_field(changeset, :aka_competitor_id)
    shiro = get_field(changeset, :shiro_competitor_id)

    if aka && shiro && aka == shiro do
      add_error(changeset, :shiro_competitor_id, "must be different from aka competitor")
    else
      changeset
    end
  end
end
