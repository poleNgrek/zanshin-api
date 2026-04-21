defmodule ZanshinApi.Competitions do
  @moduledoc """
  Competition context for tournaments, divisions, and competitors.
  """

  import Ecto.Query, warn: false

  alias ZanshinApi.Competitions.{
    Competitor,
    Division,
    DivisionMedalResult,
    DivisionRule,
    DivisionSpecialAward,
    DivisionStage,
    Tournament
  }

  alias ZanshinApi.Repo
  alias ZanshinApi.Teams.TeamMember

  def create_tournament(attrs) do
    %Tournament{}
    |> Tournament.changeset(attrs)
    |> Repo.insert()
  end

  def list_tournaments do
    Tournament |> order_by([t], desc: t.inserted_at) |> Repo.all()
  end

  def create_division(attrs) do
    %Division{}
    |> Division.changeset(attrs)
    |> Repo.insert()
  end

  def list_divisions_by_tournament(tournament_id) do
    Division
    |> where([d], d.tournament_id == ^tournament_id)
    |> order_by([d], asc: d.name)
    |> Repo.all()
  end

  def create_competitor(attrs) do
    %Competitor{}
    |> Competitor.changeset(attrs)
    |> Repo.insert()
  end

  def list_competitors do
    Competitor |> order_by([c], asc: c.display_name) |> Repo.all()
  end

  def upsert_division_rules(division_id, attrs) do
    attrs = Map.put(attrs, "division_id", division_id)

    case Repo.get_by(DivisionRule, division_id: division_id) do
      nil ->
        %DivisionRule{}
        |> DivisionRule.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> DivisionRule.changeset(attrs)
        |> Repo.update()
    end
  end

  def get_division_rules(division_id), do: Repo.get_by(DivisionRule, division_id: division_id)

  def create_division_stage(attrs) do
    %DivisionStage{}
    |> DivisionStage.changeset(attrs)
    |> Repo.insert()
  end

  def list_division_stages(division_id) do
    DivisionStage
    |> where([s], s.division_id == ^division_id)
    |> order_by([s], asc: s.sequence)
    |> Repo.all()
  end

  def create_division_medal_result(attrs) do
    with {:ok, division} <-
           fetch_division(Map.get(attrs, "division_id") || Map.get(attrs, :division_id)),
         :ok <- validate_medal_payload(division, attrs),
         :ok <- validate_place_capacity(division.id, attrs),
         changeset <- DivisionMedalResult.changeset(%DivisionMedalResult{}, with_medal(attrs)),
         :ok <- validate_medal_map(changeset) do
      Repo.insert(changeset)
    end
  end

  def list_division_medal_results(division_id) do
    DivisionMedalResult
    |> where([r], r.division_id == ^division_id)
    |> order_by([r], asc: r.place, asc: r.inserted_at)
    |> Repo.all()
  end

  def create_division_special_award(attrs) do
    with {:ok, division} <-
           fetch_division(Map.get(attrs, "division_id") || Map.get(attrs, :division_id)),
         :ok <- validate_award_payload(division, attrs) do
      %DivisionSpecialAward{}
      |> DivisionSpecialAward.changeset(attrs)
      |> Repo.insert()
    end
  end

  def list_division_special_awards(division_id) do
    DivisionSpecialAward
    |> where([a], a.division_id == ^division_id)
    |> order_by([a], asc: a.inserted_at)
    |> Repo.all()
  end

  defp fetch_division(nil), do: {:error, :division_not_found}

  defp fetch_division(division_id) do
    case Repo.get(Division, division_id) do
      nil -> {:error, :division_not_found}
      division -> {:ok, division}
    end
  end

  defp validate_medal_payload(%Division{format: :team} = division, attrs) do
    with :ok <- require_team_recipient(attrs),
         :ok <- reject_competitor_recipient(attrs),
         :ok <- validate_team_membership(division, attrs) do
      :ok
    end
  end

  defp validate_medal_payload(%Division{}, attrs) do
    with :ok <- require_competitor_recipient(attrs),
         :ok <- reject_team_recipient(attrs) do
      :ok
    end
  end

  defp validate_award_payload(%Division{format: :team} = division, attrs) do
    with :ok <- require_competitor_recipient(attrs),
         :ok <- require_team_recipient(attrs),
         :ok <- validate_team_membership(division, attrs) do
      :ok
    end
  end

  defp validate_award_payload(%Division{}, attrs) do
    with :ok <- require_competitor_recipient(attrs),
         :ok <- reject_team_recipient(attrs) do
      :ok
    end
  end

  defp validate_team_membership(%Division{id: division_id}, attrs) do
    team_id = Map.get(attrs, "team_id") || Map.get(attrs, :team_id)
    competitor_id = Map.get(attrs, "competitor_id") || Map.get(attrs, :competitor_id)

    if is_nil(competitor_id) do
      :ok
    else
      query =
        from tm in TeamMember,
          join: t in assoc(tm, :team),
          where:
            tm.team_id == ^team_id and tm.competitor_id == ^competitor_id and
              t.division_id == ^division_id,
          select: tm.id,
          limit: 1

      case Repo.one(query) do
        nil -> {:error, :competitor_not_in_team}
        _ -> :ok
      end
    end
  end

  defp validate_place_capacity(division_id, attrs) do
    place = Map.get(attrs, "place") || Map.get(attrs, :place)

    limit =
      case place do
        1 -> 1
        2 -> 1
        3 -> 2
        _ -> :invalid
      end

    case limit do
      :invalid ->
        {:error, :invalid_place}

      _ ->
        existing_count =
          DivisionMedalResult
          |> where([r], r.division_id == ^division_id and r.place == ^place)
          |> Repo.aggregate(:count)

        if existing_count < limit, do: :ok, else: {:error, :place_capacity_reached}
    end
  end

  defp validate_medal_map(changeset) do
    place = Ecto.Changeset.get_field(changeset, :place)
    medal = Ecto.Changeset.get_field(changeset, :medal)
    expected = expected_medal(place)

    if medal == expected, do: :ok, else: {:error, :invalid_medal_for_place}
  end

  defp with_medal(attrs) do
    place = Map.get(attrs, "place") || Map.get(attrs, :place)
    medal = expected_medal(place)
    Map.put(attrs, "medal", Atom.to_string(medal))
  end

  defp expected_medal(1), do: :gold
  defp expected_medal(2), do: :silver
  defp expected_medal(3), do: :bronze
  defp expected_medal(_), do: :bronze

  defp require_team_recipient(attrs) do
    if present?(Map.get(attrs, "team_id") || Map.get(attrs, :team_id)),
      do: :ok,
      else: {:error, :team_id_required}
  end

  defp reject_team_recipient(attrs) do
    if present?(Map.get(attrs, "team_id") || Map.get(attrs, :team_id)),
      do: {:error, :team_id_not_allowed},
      else: :ok
  end

  defp require_competitor_recipient(attrs) do
    if present?(Map.get(attrs, "competitor_id") || Map.get(attrs, :competitor_id)),
      do: :ok,
      else: {:error, :competitor_id_required}
  end

  defp reject_competitor_recipient(attrs) do
    if present?(Map.get(attrs, "competitor_id") || Map.get(attrs, :competitor_id)),
      do: {:error, :competitor_id_not_allowed},
      else: :ok
  end

  defp present?(value), do: not is_nil(value)
end
