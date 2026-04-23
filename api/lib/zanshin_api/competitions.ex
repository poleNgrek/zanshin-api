defmodule ZanshinApi.Competitions do
  @moduledoc """
  Competition context for tournaments, divisions, and competitors.
  """

  import Ecto.Query, warn: false

  alias ZanshinApi.Competitions.{
    BracketLink,
    BracketRound,
    BracketSlot,
    Competitor,
    Division,
    DivisionMedalResult,
    DivisionRule,
    Shiaijo,
    ShinpanAssignment,
    DivisionSpecialAward,
    DivisionStage,
    Tournament
  }

  alias ZanshinApi.Officials.Shinpan
  alias ZanshinApi.Matches.{Match, MatchEvent, ScoreEvent}
  alias ZanshinApi.Repo
  alias ZanshinApi.Teams.{Team, TeamMatch, TeamMember}

  def create_tournament(attrs) do
    %Tournament{}
    |> Tournament.changeset(attrs)
    |> Repo.insert()
  end

  def list_tournaments do
    Tournament |> order_by([t], desc: t.inserted_at) |> Repo.all()
  end

  def export_tournament_snapshot(tournament_id) do
    with %Tournament{} = tournament <- Repo.get(Tournament, tournament_id) do
      divisions = list_divisions_by_tournament(tournament.id)
      division_ids = Enum.map(divisions, & &1.id)

      rules =
        DivisionRule
        |> where([r], r.division_id in ^division_ids)
        |> Repo.all()

      stages =
        DivisionStage
        |> where([s], s.division_id in ^division_ids)
        |> order_by([s], asc: s.sequence)
        |> Repo.all()

      teams =
        Team
        |> where([t], t.division_id in ^division_ids)
        |> Repo.all()

      team_ids = Enum.map(teams, & &1.id)

      team_members =
        TeamMember
        |> where([tm], tm.team_id in ^team_ids)
        |> Repo.all()

      team_matches =
        TeamMatch
        |> where([tm], tm.division_id in ^division_ids)
        |> order_by([tm], asc: tm.inserted_at)
        |> Repo.all()

      matches =
        Match
        |> where([m], m.tournament_id == ^tournament.id)
        |> order_by([m], asc: m.inserted_at)
        |> Repo.all()

      match_ids = Enum.map(matches, & &1.id)

      match_events =
        MatchEvent
        |> where([me], me.match_id in ^match_ids)
        |> order_by([me], asc: me.inserted_at)
        |> Repo.all()

      score_events =
        ScoreEvent
        |> where([se], se.match_id in ^match_ids)
        |> order_by([se], asc: se.inserted_at)
        |> Repo.all()

      medal_results =
        DivisionMedalResult
        |> where([r], r.division_id in ^division_ids)
        |> order_by([r], asc: r.place, asc: r.inserted_at)
        |> Repo.all()

      special_awards =
        DivisionSpecialAward
        |> where([a], a.division_id in ^division_ids)
        |> order_by([a], asc: a.inserted_at)
        |> Repo.all()

      competitor_ids =
        (Enum.flat_map(matches, fn m -> [m.aka_competitor_id, m.shiro_competitor_id] end) ++
           Enum.map(team_members, & &1.competitor_id) ++
           Enum.map(medal_results, & &1.competitor_id) ++
           Enum.map(special_awards, & &1.competitor_id))
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      competitors =
        Competitor
        |> where([c], c.id in ^competitor_ids)
        |> order_by([c], asc: c.display_name)
        |> Repo.all()

      {:ok,
       %{
         metadata: %{
           schema_version: 1,
           exported_at: DateTime.utc_now(),
           source_tournament_id: tournament.id
         },
         tournament: export_map(tournament),
         divisions: Enum.map(divisions, &export_map/1),
         division_rules: Enum.map(rules, &export_map/1),
         division_stages: Enum.map(stages, &export_map/1),
         competitors: Enum.map(competitors, &export_map/1),
         teams: Enum.map(teams, &export_map/1),
         team_members: Enum.map(team_members, &export_map/1),
         team_matches: Enum.map(team_matches, &export_map/1),
         matches: Enum.map(matches, &export_map/1),
         match_events: Enum.map(match_events, &export_map/1),
         score_events: Enum.map(score_events, &export_map/1),
         division_medal_results: Enum.map(medal_results, &export_map/1),
         division_special_awards: Enum.map(special_awards, &export_map/1)
       }}
    else
      nil -> {:error, :tournament_not_found}
    end
  end

  def compute_division_results(division_id) do
    with {:ok, division} <- fetch_division(division_id),
         :ok <- ensure_computable_division(division),
         {:ok, final_result, bronze_recipients} <- compute_podium(division),
         {:ok, _} <- replace_division_medal_results(division, final_result, bronze_recipients) do
      {:ok, list_division_medal_results(division.id)}
    end
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

  def create_shiaijo(attrs) do
    %Shiaijo{}
    |> Shiaijo.changeset(attrs)
    |> Repo.insert()
  end

  def list_shiaijos(tournament_id) do
    Shiaijo
    |> where([shiaijo], shiaijo.tournament_id == ^tournament_id)
    |> order_by([shiaijo], asc: shiaijo.name)
    |> Repo.all()
  end

  def create_shinpan(attrs) do
    %Shinpan{}
    |> Shinpan.changeset(attrs)
    |> Repo.insert()
  end

  def list_shinpans(tournament_id) do
    Shinpan
    |> where([shinpan], shinpan.tournament_id == ^tournament_id)
    |> order_by([shinpan], asc: shinpan.display_name)
    |> Repo.all()
  end

  def create_shinpan_assignment(attrs) do
    with :ok <- validate_assignment_scope(attrs),
         changeset <- ShinpanAssignment.changeset(%ShinpanAssignment{}, attrs),
         :ok <- ensure_shinpan_available(changeset),
         :ok <- ensure_shiaijo_available(changeset) do
      Repo.insert(changeset)
    end
  end

  def list_shinpan_assignments(tournament_id) do
    ShinpanAssignment
    |> where([assignment], assignment.tournament_id == ^tournament_id)
    |> order_by([assignment], asc: assignment.starts_at, asc: assignment.inserted_at)
    |> Repo.all()
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

  def create_bracket_round(attrs) do
    %BracketRound{}
    |> BracketRound.changeset(attrs)
    |> Repo.insert()
  end

  def list_bracket_rounds(division_id) do
    BracketRound
    |> where([round], round.division_id == ^division_id)
    |> order_by([round], asc: round.round_number)
    |> Repo.all()
  end

  def create_bracket_slot(attrs) do
    %BracketSlot{}
    |> BracketSlot.changeset(attrs)
    |> Repo.insert()
  end

  def list_bracket_slots(round_id) do
    BracketSlot
    |> where([slot], slot.round_id == ^round_id)
    |> order_by([slot], asc: slot.slot_number)
    |> Repo.all()
  end

  def create_bracket_link(attrs) do
    %BracketLink{}
    |> BracketLink.changeset(attrs)
    |> Repo.insert()
  end

  def list_bracket_links_from(slot_id) do
    BracketLink
    |> where([link], link.from_slot_id == ^slot_id)
    |> order_by([link], asc: link.inserted_at)
    |> Repo.all()
  end

  def bracket_traversal(division_id) do
    rounds = list_bracket_rounds(division_id)
    round_ids = Enum.map(rounds, & &1.id)

    slots =
      BracketSlot
      |> where([slot], slot.round_id in ^round_ids)
      |> order_by([slot], asc: slot.round_id, asc: slot.slot_number)
      |> Repo.all()

    slot_ids = Enum.map(slots, & &1.id)

    links =
      BracketLink
      |> where([link], link.from_slot_id in ^slot_ids or link.to_slot_id in ^slot_ids)
      |> order_by([link], asc: link.inserted_at)
      |> Repo.all()

    {:ok,
     %{
       rounds: rounds,
       slots: slots,
       links: links
     }}
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
         :ok <- validate_team_in_division(division, attrs),
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
         :ok <- validate_team_in_division(division, attrs),
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

  defp validate_team_in_division(%Division{id: division_id}, attrs) do
    team_id = Map.get(attrs, "team_id") || Map.get(attrs, :team_id)

    if is_nil(team_id) do
      :ok
    else
      case Repo.get(Team, team_id) do
        %Team{division_id: ^division_id} -> :ok
        _ -> {:error, :team_not_in_division}
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

  defp ensure_computable_division(%Division{}), do: :ok

  defp compute_podium(%Division{format: :team, id: division_id}) do
    with {:ok, winners, matches} <- resolve_completed_team_match_winners(division_id),
         {:ok, final_match} <- final_match(matches),
         {:ok, final_result} <- fetch_winner(winners, final_match.id),
         {:ok, bronze_teams} <-
           resolve_semifinal_losers(winners, matches, final_match, final_result) do
      {:ok, final_result, bronze_teams}
    end
  end

  defp compute_podium(%Division{id: division_id}) do
    with {:ok, winners, matches} <- resolve_completed_match_winners(division_id),
         {:ok, final_match} <- final_match(matches),
         {:ok, final_result} <- fetch_winner(winners, final_match.id),
         {:ok, bronze_competitors} <-
           resolve_semifinal_losers(winners, matches, final_match, final_result) do
      {:ok, final_result, bronze_competitors}
    end
  end

  defp export_map(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, key, export_value(value))
    end)
  end

  defp export_value(%Ecto.Association.NotLoaded{}), do: nil
  defp export_value(value) when value in [true, false, nil], do: value
  defp export_value(value) when is_atom(value), do: Atom.to_string(value)
  defp export_value(value), do: value

  defp resolve_completed_match_winners(division_id) do
    matches =
      Match
      |> where([m], m.division_id == ^division_id and m.state in [:completed, :verified])
      |> order_by([m], asc: m.inserted_at)
      |> Repo.all()

    if Enum.empty?(matches) do
      {:error, :insufficient_completed_matches}
    else
      match_ids = Enum.map(matches, & &1.id)

      score_events =
        ScoreEvent
        |> where([s], s.match_id in ^match_ids)
        |> Repo.all()

      score_map = Enum.group_by(score_events, & &1.match_id)

      winners =
        Enum.reduce_while(matches, %{}, fn match, acc ->
          case resolve_match_winner(match, Map.get(score_map, match.id, [])) do
            {:ok, winner} -> {:cont, Map.put(acc, match.id, winner)}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      case winners do
        {:error, reason} -> {:error, reason}
        winner_map -> {:ok, winner_map, matches}
      end
    end
  end

  defp resolve_match_winner(%Match{} = match, score_events) do
    aka_points =
      Enum.count(score_events, fn e ->
        e.side == :aka and e.score_type in [:ippon, :hansoku]
      end)

    shiro_points =
      Enum.count(score_events, fn e ->
        e.side == :shiro and e.score_type in [:ippon, :hansoku]
      end)

    cond do
      aka_points > shiro_points ->
        {:ok, %{winner_id: match.aka_competitor_id, loser_id: match.shiro_competitor_id}}

      shiro_points > aka_points ->
        {:ok, %{winner_id: match.shiro_competitor_id, loser_id: match.aka_competitor_id}}

      true ->
        {:error, :cannot_compute_match_winner}
    end
  end

  defp resolve_completed_team_match_winners(division_id) do
    matches =
      TeamMatch
      |> where([m], m.division_id == ^division_id and m.state == :completed)
      |> order_by([m], asc: m.inserted_at)
      |> Repo.all()

    if Enum.empty?(matches) do
      {:error, :insufficient_completed_matches}
    else
      winners =
        Enum.reduce_while(matches, %{}, fn match, acc ->
          case resolve_team_match_winner(match) do
            {:ok, winner} -> {:cont, Map.put(acc, match.id, winner)}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      case winners do
        {:error, reason} -> {:error, reason}
        winner_map -> {:ok, winner_map, matches}
      end
    end
  end

  defp resolve_team_match_winner(%TeamMatch{} = match) do
    cond do
      match.winner_team_id && match.loser_team_id ->
        {:ok, %{winner_id: match.winner_team_id, loser_id: match.loser_team_id}}

      match.representative_match_required and match.representative_winner_team_id ->
        loser_id =
          if(match.representative_winner_team_id == match.team_a_id,
            do: match.team_b_id,
            else: match.team_a_id
          )

        {:ok, %{winner_id: match.representative_winner_team_id, loser_id: loser_id}}

      match.team_a_wins > match.team_b_wins ->
        {:ok, %{winner_id: match.team_a_id, loser_id: match.team_b_id}}

      match.team_b_wins > match.team_a_wins ->
        {:ok, %{winner_id: match.team_b_id, loser_id: match.team_a_id}}

      true ->
        {:error, :cannot_compute_team_match_winner}
    end
  end

  defp final_match(matches) do
    case List.last(matches) do
      nil -> {:error, :insufficient_completed_matches}
      match -> {:ok, match}
    end
  end

  defp fetch_winner(winner_map, match_id) do
    case Map.fetch(winner_map, match_id) do
      {:ok, winner} -> {:ok, winner}
      :error -> {:error, :cannot_compute_match_winner}
    end
  end

  defp resolve_semifinal_losers(winners, matches, final_match, %{
         winner_id: winner_id,
         loser_id: loser_id
       }) do
    prior_matches = Enum.reject(matches, &(&1.id == final_match.id))
    finalists = [winner_id, loser_id]

    losers =
      Enum.map(finalists, fn finalist_id ->
        prior_matches
        |> Enum.reverse()
        |> Enum.find_value(fn match ->
          case Map.get(winners, match.id) do
            %{winner_id: ^finalist_id, loser_id: loser} -> loser
            _ -> nil
          end
        end)
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    if length(losers) == 2, do: {:ok, losers}, else: {:error, :insufficient_semifinal_data}
  end

  defp replace_division_medal_results(
         %Division{id: division_id, format: :team},
         final_result,
         bronze_teams
       ) do
    Repo.transaction(fn ->
      from(r in DivisionMedalResult, where: r.division_id == ^division_id) |> Repo.delete_all()

      with {:ok, _} <-
             create_division_medal_result(%{
               "division_id" => division_id,
               "place" => 1,
               "team_id" => final_result.winner_id
             }),
           {:ok, _} <-
             create_division_medal_result(%{
               "division_id" => division_id,
               "place" => 2,
               "team_id" => final_result.loser_id
             }),
           {:ok, _} <- insert_bronze_team_medals(division_id, bronze_teams) do
        :ok
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, :ok} -> {:ok, :ok}
      {:error, reason} -> {:error, reason}
    end
  end

  defp replace_division_medal_results(
         %Division{id: division_id},
         final_result,
         bronze_competitors
       ) do
    Repo.transaction(fn ->
      from(r in DivisionMedalResult, where: r.division_id == ^division_id) |> Repo.delete_all()

      with {:ok, _} <-
             create_division_medal_result(%{
               "division_id" => division_id,
               "place" => 1,
               "competitor_id" => final_result.winner_id
             }),
           {:ok, _} <-
             create_division_medal_result(%{
               "division_id" => division_id,
               "place" => 2,
               "competitor_id" => final_result.loser_id
             }),
           {:ok, _} <- insert_bronze_medals(division_id, bronze_competitors) do
        :ok
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, :ok} -> {:ok, :ok}
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_bronze_medals(division_id, competitors) do
    Enum.reduce_while(competitors, {:ok, :ok}, fn competitor_id, _acc ->
      case create_division_medal_result(%{
             "division_id" => division_id,
             "place" => 3,
             "competitor_id" => competitor_id
           }) do
        {:ok, _} -> {:cont, {:ok, :ok}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp insert_bronze_team_medals(division_id, teams) do
    Enum.reduce_while(teams, {:ok, :ok}, fn team_id, _acc ->
      case create_division_medal_result(%{
             "division_id" => division_id,
             "place" => 3,
             "team_id" => team_id
           }) do
        {:ok, _} -> {:cont, {:ok, :ok}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

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

  defp validate_assignment_scope(attrs) do
    tournament_id = Map.get(attrs, "tournament_id") || Map.get(attrs, :tournament_id)
    shiaijo_id = Map.get(attrs, "shiaijo_id") || Map.get(attrs, :shiaijo_id)
    shinpan_id = Map.get(attrs, "shinpan_id") || Map.get(attrs, :shinpan_id)

    with %Shiaijo{tournament_id: ^tournament_id} <- Repo.get(Shiaijo, shiaijo_id),
         %Shinpan{tournament_id: ^tournament_id} <- Repo.get(Shinpan, shinpan_id) do
      :ok
    else
      _ -> {:error, :assignment_scope_mismatch}
    end
  end

  defp ensure_shinpan_available(changeset) do
    shinpan_id = Ecto.Changeset.get_field(changeset, :shinpan_id)
    starts_at = Ecto.Changeset.get_field(changeset, :starts_at)
    ends_at = Ecto.Changeset.get_field(changeset, :ends_at)

    conflict? =
      ShinpanAssignment
      |> where(
        [assignment],
        assignment.shinpan_id == ^shinpan_id and assignment.starts_at < ^ends_at and
          assignment.ends_at > ^starts_at
      )
      |> Repo.exists?()

    if conflict?, do: {:error, :shinpan_schedule_conflict}, else: :ok
  end

  defp ensure_shiaijo_available(changeset) do
    shiaijo_id = Ecto.Changeset.get_field(changeset, :shiaijo_id)
    starts_at = Ecto.Changeset.get_field(changeset, :starts_at)
    ends_at = Ecto.Changeset.get_field(changeset, :ends_at)

    conflict? =
      ShinpanAssignment
      |> where(
        [assignment],
        assignment.shiaijo_id == ^shiaijo_id and assignment.starts_at < ^ends_at and
          assignment.ends_at > ^starts_at
      )
      |> Repo.exists?()

    if conflict?, do: {:error, :shiaijo_schedule_conflict}, else: :ok
  end

  defp present?(value), do: not is_nil(value)
end
