defmodule ZanshinApi.Grading.GradingResult do
  @moduledoc "Individual grading outcome linked to a competitor."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "grading_results" do
    field :grade, :string
    field :passed, :boolean, default: false

    belongs_to :session, ZanshinApi.Grading.GradingSession, foreign_key: :grading_session_id
    belongs_to :competitor, ZanshinApi.Competitions.Competitor

    timestamps(type: :utc_datetime)
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [:grade, :passed, :grading_session_id, :competitor_id])
    |> validate_required([:grade, :passed, :grading_session_id, :competitor_id])
    |> foreign_key_constraint(:grading_session_id)
    |> foreign_key_constraint(:competitor_id)
  end
end
