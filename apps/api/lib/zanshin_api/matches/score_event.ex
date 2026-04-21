defmodule ZanshinApi.Matches.ScoreEvent do
  @moduledoc """
  Scoring events (`ippon` / `hansoku`) captured during ongoing matches.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @score_types [:ippon, :hansoku]
  @sides [:aka, :shiro]
  @roles [:admin, :shinpan]

  schema "score_events" do
    field :score_type, Ecto.Enum, values: @score_types
    field :side, Ecto.Enum, values: @sides
    field :actor_role, Ecto.Enum, values: @roles

    belongs_to :match, ZanshinApi.Matches.Match

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:score_type, :side, :actor_role, :match_id])
    |> validate_required([:score_type, :side, :actor_role, :match_id])
    |> foreign_key_constraint(:match_id)
  end
end
