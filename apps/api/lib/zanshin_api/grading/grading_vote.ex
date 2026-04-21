defmodule ZanshinApi.Grading.GradingVote do
  @moduledoc "Per-part pass/fail examiner vote for a grading result."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @parts [:jitsugi, :kata, :written]
  @decisions [:pass, :fail]

  schema "grading_votes" do
    field :part, Ecto.Enum, values: @parts
    field :decision, Ecto.Enum, values: @decisions
    field :note, :string

    belongs_to :result, ZanshinApi.Grading.GradingResult, foreign_key: :grading_result_id
    belongs_to :examiner, ZanshinApi.Grading.GradingExaminer

    timestamps(type: :utc_datetime)
  end

  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:grading_result_id, :examiner_id, :part, :decision, :note])
    |> validate_required([:grading_result_id, :examiner_id, :part, :decision])
    |> foreign_key_constraint(:grading_result_id)
    |> foreign_key_constraint(:examiner_id)
    |> unique_constraint([:grading_result_id, :examiner_id, :part],
      name: :grading_votes_grading_result_id_examiner_id_part_index
    )
  end
end
