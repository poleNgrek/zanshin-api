defmodule ZanshinApi.Grading.GradingNote do
  @moduledoc "Examiner qualitative note for grading review and audit."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @parts [:jitsugi, :kata, :written]

  schema "grading_notes" do
    field :part, Ecto.Enum, values: @parts
    field :note, :string

    belongs_to :result, ZanshinApi.Grading.GradingResult, foreign_key: :grading_result_id
    belongs_to :examiner, ZanshinApi.Grading.GradingExaminer

    timestamps(type: :utc_datetime)
  end

  def changeset(note, attrs) do
    note
    |> cast(attrs, [:grading_result_id, :examiner_id, :part, :note])
    |> validate_required([:grading_result_id, :examiner_id, :note])
    |> foreign_key_constraint(:grading_result_id)
    |> foreign_key_constraint(:examiner_id)
  end
end
