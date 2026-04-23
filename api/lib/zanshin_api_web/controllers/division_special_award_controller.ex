defmodule ZanshinApiWeb.DivisionSpecialAwardController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Competitions
  alias ZanshinApi.Competitions.DivisionSpecialAward
  alias ZanshinApiWeb.Pagination

  def index(conn, %{"division_id" => division_id} = params) do
    Pagination.json_paginated(
      conn,
      params,
      Competitions.list_division_special_awards(division_id),
      &serialize/1
    )
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, award} <- Competitions.create_division_special_award(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize(award)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, reason} when is_atom(reason) ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: Atom.to_string(reason)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_division_award_payload", details: changeset_errors(changeset)})
    end
  end

  defp authorize_write(conn) do
    if conn.assigns[:current_role] in [:admin, :timekeeper], do: :ok, else: {:error, :forbidden}
  end

  defp serialize(%DivisionSpecialAward{} = award) do
    %{
      id: award.id,
      division_id: award.division_id,
      award_type: to_string(award.award_type),
      competitor_id: award.competitor_id,
      team_id: award.team_id
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
