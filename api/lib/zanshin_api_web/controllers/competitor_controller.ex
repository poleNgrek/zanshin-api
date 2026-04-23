defmodule ZanshinApiWeb.CompetitorController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.Competitor
  alias ZanshinApiWeb.Pagination

  def index(conn, params) do
    Pagination.json_paginated(conn, params, Competitions.list_competitors(), &serialize/1)
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, competitor} <- Competitions.create_competitor(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(competitor)})
    else
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_competitor_payload", details: changeset_errors(changeset)})
    end
  end

  defp serialize(%Competitor{} = competitor) do
    %{
      id: competitor.id,
      display_name: competitor.display_name,
      federation_id: competitor.federation_id,
      birth_date: competitor.birth_date,
      avatar_url: competitor.avatar_url,
      preferred_stance:
        if(competitor.preferred_stance, do: to_string(competitor.preferred_stance), else: nil),
      grade_value: competitor.grade_value,
      grade_type: if(competitor.grade_type, do: to_string(competitor.grade_type), else: nil),
      grade_title: if(competitor.grade_title, do: to_string(competitor.grade_title), else: nil)
    }
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
