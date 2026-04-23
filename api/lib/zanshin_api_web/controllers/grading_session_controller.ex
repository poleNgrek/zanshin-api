defmodule ZanshinApiWeb.GradingSessionController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Grading.GradingSession
  alias ZanshinApi.Gradings
  alias ZanshinApiWeb.Pagination

  def index(conn, params) do
    case Map.get(params, "tournament_id") do
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "tournament_id_required"})

      tournament_id ->
        Pagination.json_paginated(
          conn,
          params,
          Gradings.list_sessions_by_tournament(tournament_id),
          &serialize/1
        )
    end
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, session} <- Gradings.create_session(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(session)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_grading_session_payload", details: changeset_errors(changeset)})
    end
  end

  defp serialize(%GradingSession{} = session) do
    %{
      id: session.id,
      tournament_id: session.tournament_id,
      name: session.name,
      held_on: session.held_on,
      written_required: session.written_required,
      kata_carryover_months: session.kata_carryover_months,
      written_carryover_months: session.written_carryover_months,
      required_pass_votes: session.required_pass_votes
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
