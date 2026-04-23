defmodule ZanshinApi.Competitions.BracketRound do
  @moduledoc "Explicit bracket round node."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bracket_rounds" do
    field :round_number, :integer
    field :label, :string

    belongs_to :division, ZanshinApi.Competitions.Division
    has_many :slots, ZanshinApi.Competitions.BracketSlot, foreign_key: :round_id

    timestamps(type: :utc_datetime)
  end

  def changeset(round, attrs) do
    round
    |> cast(attrs, [:division_id, :round_number, :label])
    |> validate_required([:division_id, :round_number])
    |> validate_number(:round_number, greater_than: 0)
    |> foreign_key_constraint(:division_id)
    |> unique_constraint([:division_id, :round_number],
      name: :bracket_rounds_division_id_round_number_index
    )
  end
end
