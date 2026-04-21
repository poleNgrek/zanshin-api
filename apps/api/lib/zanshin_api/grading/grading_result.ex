defmodule ZanshinApi.Grading.GradingResult do
  @moduledoc "Individual grading outcome linked to a competitor."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @final_results [:pass, :fail, :pending]
  @part_results [:pass, :fail, :not_attempted, :carried_over, :waived]
  @stances [:chudan, :jodan_left, :jodan_right, :nito, :gedan, :hasso, :waki, :other]

  schema "grading_results" do
    field :grade, :string
    field :passed, :boolean, default: false
    field :target_grade, :string
    field :final_result, Ecto.Enum, values: @final_results, default: :pending
    field :jitsugi_result, Ecto.Enum, values: @part_results, default: :not_attempted
    field :kata_result, Ecto.Enum, values: @part_results, default: :not_attempted
    field :written_result, Ecto.Enum, values: @part_results, default: :not_attempted
    field :carryover_until, :date
    field :declared_stance, Ecto.Enum, values: @stances

    belongs_to :session, ZanshinApi.Grading.GradingSession, foreign_key: :grading_session_id
    belongs_to :competitor, ZanshinApi.Competitions.Competitor
    has_many :votes, ZanshinApi.Grading.GradingVote
    has_many :notes, ZanshinApi.Grading.GradingNote

    timestamps(type: :utc_datetime)
  end

  def changeset(result, attrs) do
    attrs = normalize_legacy_attrs(attrs)

    result
    |> cast(attrs, [
      :grade,
      :passed,
      :target_grade,
      :final_result,
      :jitsugi_result,
      :kata_result,
      :written_result,
      :carryover_until,
      :declared_stance,
      :grading_session_id,
      :competitor_id
    ])
    |> validate_required([
      :target_grade,
      :final_result,
      :jitsugi_result,
      :kata_result,
      :written_result,
      :grading_session_id,
      :competitor_id
    ])
    |> maybe_sync_legacy_fields()
    |> foreign_key_constraint(:grading_session_id)
    |> foreign_key_constraint(:competitor_id)
  end

  defp normalize_legacy_attrs(%{} = attrs) do
    grade = Map.get(attrs, "grade") || Map.get(attrs, :grade)
    target_grade = Map.get(attrs, "target_grade") || Map.get(attrs, :target_grade)

    attrs =
      if is_nil(target_grade) and not is_nil(grade) do
        Map.put(attrs, "target_grade", grade)
      else
        attrs
      end

    case Map.get(attrs, "passed") || Map.get(attrs, :passed) do
      true -> Map.put(attrs, "final_result", "pass")
      false -> Map.put_new(attrs, "final_result", "fail")
      _ -> attrs
    end
  end

  defp normalize_legacy_attrs(attrs), do: attrs

  defp maybe_sync_legacy_fields(changeset) do
    final_result = get_field(changeset, :final_result)
    target_grade = get_field(changeset, :target_grade)

    changeset
    |> put_change(:grade, target_grade)
    |> put_change(:passed, final_result == :pass)
  end
end
