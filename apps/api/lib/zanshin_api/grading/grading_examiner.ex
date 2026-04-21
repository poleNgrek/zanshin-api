defmodule ZanshinApi.Grading.GradingExaminer do
  @moduledoc "Examiner profile for grading panels."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "grading_examiners" do
    field :display_name, :string
    field :federation_id, :string
    field :federation_name, :string
    field :grade, :string
    field :title, :string

    has_many :panel_assignments, ZanshinApi.Grading.GradingPanelAssignment,
      foreign_key: :examiner_id

    has_many :votes, ZanshinApi.Grading.GradingVote, foreign_key: :examiner_id
    has_many :notes, ZanshinApi.Grading.GradingNote, foreign_key: :examiner_id

    timestamps(type: :utc_datetime)
  end

  def changeset(examiner, attrs) do
    examiner
    |> cast(attrs, [:display_name, :federation_id, :federation_name, :grade, :title])
    |> validate_required([:display_name])
    |> validate_length(:display_name, min: 2, max: 120)
    |> unique_constraint(:federation_id)
  end
end
