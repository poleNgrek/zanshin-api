defmodule ZanshinApi.Grading.GradingSession do
  @moduledoc "Kyu/Dan grading session model."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "grading_sessions" do
    field :name, :string
    field :held_on, :date
    field :written_required, :boolean, default: true
    field :kata_carryover_months, :integer, default: 12
    field :written_carryover_months, :integer, default: 12
    field :required_pass_votes, :integer

    belongs_to :tournament, ZanshinApi.Competitions.Tournament
    has_many :results, ZanshinApi.Grading.GradingResult
    has_many :panel_assignments, ZanshinApi.Grading.GradingPanelAssignment

    timestamps(type: :utc_datetime)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [
      :name,
      :held_on,
      :tournament_id,
      :written_required,
      :kata_carryover_months,
      :written_carryover_months,
      :required_pass_votes
    ])
    |> validate_required([:name, :tournament_id])
    |> validate_number(:kata_carryover_months, greater_than_or_equal_to: 0)
    |> validate_number(:written_carryover_months, greater_than_or_equal_to: 0)
    |> validate_number(:required_pass_votes, greater_than: 0)
    |> foreign_key_constraint(:tournament_id)
  end
end
