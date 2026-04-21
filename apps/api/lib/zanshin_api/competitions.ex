defmodule ZanshinApi.Competitions do
  @moduledoc """
  Competition context for tournaments, divisions, and competitors.
  """

  import Ecto.Query, warn: false
  alias ZanshinApi.Competitions.{Competitor, Division, DivisionRule, Tournament}
  alias ZanshinApi.Repo

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
end
