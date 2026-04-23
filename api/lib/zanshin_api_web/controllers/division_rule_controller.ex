defmodule ZanshinApiWeb.DivisionRuleController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.DivisionRule

  def show(conn, %{"id" => division_id}) do
    case Competitions.get_division_rules(division_id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "division_rules_not_found"})
      rules -> json(conn, %{data: serialize(rules)})
    end
  end

  def upsert(conn, %{"id" => division_id} = params) do
    with :ok <- authorize_write(conn),
         {:ok, rules} <- Competitions.upsert_division_rules(division_id, Map.delete(params, "id")) do
      json(conn, %{data: serialize(rules)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_division_rules_payload", details: changeset_errors(changeset)})
    end
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp serialize(%DivisionRule{} = rule) do
    %{
      id: rule.id,
      division_id: rule.division_id,
      category_type: to_string(rule.category_type),
      age_group: to_string(rule.age_group),
      min_age: rule.min_age,
      max_age: rule.max_age,
      match_duration_seconds: rule.match_duration_seconds,
      encho_mode: to_string(rule.encho_mode),
      encho_duration_seconds: rule.encho_duration_seconds,
      allow_tsuki: rule.allow_tsuki,
      team_size: rule.team_size,
      scoring_mode: to_string(rule.scoring_mode),
      representative_match_enabled: rule.representative_match_enabled
    }
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
