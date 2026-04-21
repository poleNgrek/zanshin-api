defmodule ZanshinApi.Grading.GradingPanelAssignment do
  @moduledoc "Examiner assignment to a grading session panel."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @roles [:head, :member]

  schema "grading_panel_assignments" do
    field :role, Ecto.Enum, values: @roles, default: :member

    belongs_to :session, ZanshinApi.Grading.GradingSession, foreign_key: :grading_session_id
    belongs_to :examiner, ZanshinApi.Grading.GradingExaminer

    timestamps(type: :utc_datetime)
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:grading_session_id, :examiner_id, :role])
    |> validate_required([:grading_session_id, :examiner_id, :role])
    |> foreign_key_constraint(:grading_session_id)
    |> foreign_key_constraint(:examiner_id)
    |> unique_constraint([:grading_session_id, :examiner_id],
      name: :grading_panel_assignments_grading_session_id_examiner_id_index
    )
  end
end
