defmodule ZanshinApiWeb.DivisionStageController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.DivisionStage
  alias ZanshinApiWeb.Pagination

  def index(conn, params) do
    case Map.get(params, "division_id") do
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "division_id_required"})

      division_id ->
        Pagination.json_paginated(
          conn,
          params,
          Competitions.list_division_stages(division_id),
          &serialize/1
        )
    end
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, stage} <- Competitions.create_division_stage(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(stage)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_division_stage_payload", details: changeset_errors(changeset)})
    end
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp serialize(%DivisionStage{} = stage) do
    %{
      id: stage.id,
      division_id: stage.division_id,
      stage_type: to_string(stage.stage_type),
      sequence: stage.sequence,
      advances_count: stage.advances_count
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
