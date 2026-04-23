defmodule ZanshinApi.Competitions.BracketLink do
  @moduledoc "Directed edge between bracket slots."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @outcomes [:winner, :loser]

  schema "bracket_links" do
    field :outcome, Ecto.Enum, values: @outcomes, default: :winner

    belongs_to :from_slot, ZanshinApi.Competitions.BracketSlot
    belongs_to :to_slot, ZanshinApi.Competitions.BracketSlot

    timestamps(type: :utc_datetime)
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:from_slot_id, :to_slot_id, :outcome])
    |> validate_required([:from_slot_id, :to_slot_id, :outcome])
    |> foreign_key_constraint(:from_slot_id)
    |> foreign_key_constraint(:to_slot_id)
    |> unique_constraint([:from_slot_id, :to_slot_id, :outcome],
      name: :bracket_links_from_slot_id_to_slot_id_outcome_index
    )
    |> validate_distinct_slots()
  end

  defp validate_distinct_slots(changeset) do
    from_slot_id = get_field(changeset, :from_slot_id)
    to_slot_id = get_field(changeset, :to_slot_id)

    if not is_nil(from_slot_id) and from_slot_id == to_slot_id do
      add_error(changeset, :to_slot_id, "cannot equal from_slot_id")
    else
      changeset
    end
  end
end
