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
  @targets [:men, :kote, :do, :tsuki]
  @roles [:admin, :shinpan]

  schema "score_events" do
    field :score_type, Ecto.Enum, values: @score_types
    field :side, Ecto.Enum, values: @sides
    field :target, Ecto.Enum, values: @targets
    field :actor_role, Ecto.Enum, values: @roles

    belongs_to :match, ZanshinApi.Matches.Match

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:score_type, :side, :target, :actor_role, :match_id])
    |> validate_required([:score_type, :side, :actor_role, :match_id])
    |> validate_target_requirements()
    |> foreign_key_constraint(:match_id)
  end

  defp validate_target_requirements(changeset) do
    case {get_field(changeset, :score_type), get_field(changeset, :target)} do
      {:ippon, nil} ->
        add_error(changeset, :target, "is required for ippon")

      {:ippon, _} ->
        changeset

      {:hansoku, _} ->
        changeset
    end
  end
end
