defmodule ZanshinApi.Competitions.DivisionStage do
  @moduledoc """
  Ordered competition stages for a division progression plan.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @stage_types [:round_robin, :knockout, :pool_to_knockout, :king_of_hill, :points_accumulation]

  schema "division_stages" do
    field :stage_type, Ecto.Enum, values: @stage_types
    field :sequence, :integer
    field :advances_count, :integer

    belongs_to :division, ZanshinApi.Competitions.Division

    timestamps(type: :utc_datetime)
  end

  def changeset(stage, attrs) do
    stage
    |> cast(attrs, [:division_id, :stage_type, :sequence, :advances_count])
    |> validate_required([:division_id, :stage_type, :sequence])
    |> validate_number(:sequence, greater_than: 0)
    |> validate_number(:advances_count, greater_than: 0)
    |> foreign_key_constraint(:division_id)
    |> unique_constraint([:division_id, :sequence],
      name: :division_stages_division_id_sequence_index
    )
  end
end
