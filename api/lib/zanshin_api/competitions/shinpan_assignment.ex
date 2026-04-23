defmodule ZanshinApi.Competitions.ShinpanAssignment do
  @moduledoc "Scheduled shinpan assignment on a shiaijo."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles [:head, :member, :reserve]

  schema "shinpan_assignments" do
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :role, Ecto.Enum, values: @roles, default: :head

    belongs_to :tournament, ZanshinApi.Competitions.Tournament
    belongs_to :shiaijo, ZanshinApi.Competitions.Shiaijo
    belongs_to :shinpan, ZanshinApi.Officials.Shinpan
    belongs_to :match, ZanshinApi.Matches.Match

    timestamps(type: :utc_datetime)
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [
      :tournament_id,
      :shiaijo_id,
      :shinpan_id,
      :match_id,
      :starts_at,
      :ends_at,
      :role
    ])
    |> validate_required([:tournament_id, :shiaijo_id, :shinpan_id, :starts_at, :ends_at, :role])
    |> validate_time_window()
    |> foreign_key_constraint(:tournament_id)
    |> foreign_key_constraint(:shiaijo_id)
    |> foreign_key_constraint(:shinpan_id)
    |> foreign_key_constraint(:match_id)
  end

  defp validate_time_window(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if is_nil(starts_at) or is_nil(ends_at) do
      changeset
    else
      case DateTime.compare(starts_at, ends_at) do
        :lt -> changeset
        _ -> add_error(changeset, :ends_at, "must be after starts_at")
      end
    end
  end
end
