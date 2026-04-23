defmodule ZanshinApi.Competitions.BracketSlot do
  @moduledoc "Explicit bracket slot node."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bracket_slots" do
    field :slot_number, :integer

    belongs_to :round, ZanshinApi.Competitions.BracketRound, foreign_key: :round_id
    belongs_to :match, ZanshinApi.Matches.Match
    has_many :outgoing_links, ZanshinApi.Competitions.BracketLink, foreign_key: :from_slot_id
    has_many :incoming_links, ZanshinApi.Competitions.BracketLink, foreign_key: :to_slot_id

    timestamps(type: :utc_datetime)
  end

  def changeset(slot, attrs) do
    slot
    |> cast(attrs, [:round_id, :slot_number, :match_id])
    |> validate_required([:round_id, :slot_number])
    |> validate_number(:slot_number, greater_than: 0)
    |> foreign_key_constraint(:round_id)
    |> foreign_key_constraint(:match_id)
    |> unique_constraint([:round_id, :slot_number],
      name: :bracket_slots_round_id_slot_number_index
    )
  end
end
