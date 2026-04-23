defmodule ZanshinApi.Competitions.DivisionRule do
  @moduledoc """
  Rule configuration scoped to a division.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @category_types [:women, :men, :mixed, :open]
  @age_groups [:children, :youth, :adult, :masters, :open]
  @encho_modes [:unlimited_sudden_death, :time_limited_sudden_death]
  @scoring_modes [:match_wins_then_ippon, :ippon_only]

  schema "division_rules" do
    field :category_type, Ecto.Enum, values: @category_types, default: :open
    field :age_group, Ecto.Enum, values: @age_groups, default: :open
    field :min_age, :integer
    field :max_age, :integer
    field :match_duration_seconds, :integer, default: 300
    field :encho_mode, Ecto.Enum, values: @encho_modes, default: :unlimited_sudden_death
    field :encho_duration_seconds, :integer
    field :allow_tsuki, :boolean, default: true
    field :team_size, :integer, default: 5
    field :scoring_mode, Ecto.Enum, values: @scoring_modes, default: :match_wins_then_ippon
    field :representative_match_enabled, :boolean, default: true

    belongs_to :division, ZanshinApi.Competitions.Division

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :division_id,
      :category_type,
      :age_group,
      :min_age,
      :max_age,
      :match_duration_seconds,
      :encho_mode,
      :encho_duration_seconds,
      :allow_tsuki,
      :team_size,
      :scoring_mode,
      :representative_match_enabled
    ])
    |> validate_required([
      :division_id,
      :category_type,
      :age_group,
      :match_duration_seconds,
      :allow_tsuki
    ])
    |> validate_number(:match_duration_seconds, greater_than: 0)
    |> validate_number(:team_size, greater_than: 0)
    |> validate_age_range()
    |> validate_encho_duration()
    |> foreign_key_constraint(:division_id)
    |> unique_constraint(:division_id)
  end

  defp validate_age_range(changeset) do
    min_age = get_field(changeset, :min_age)
    max_age = get_field(changeset, :max_age)

    cond do
      is_nil(min_age) and is_nil(max_age) ->
        changeset

      is_integer(min_age) and is_integer(max_age) and min_age <= max_age ->
        changeset

      true ->
        add_error(changeset, :max_age, "must be greater than or equal to min_age")
    end
  end

  defp validate_encho_duration(changeset) do
    mode = get_field(changeset, :encho_mode)
    duration = get_field(changeset, :encho_duration_seconds)

    case {mode, duration} do
      {:time_limited_sudden_death, value} when is_integer(value) and value > 0 ->
        changeset

      {:time_limited_sudden_death, _} ->
        add_error(changeset, :encho_duration_seconds, "is required for time-limited encho")

      _ ->
        changeset
    end
  end
end
