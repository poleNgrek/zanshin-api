defmodule ZanshinApiWeb.GradingSessionController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Grading.GradingSession
  alias ZanshinApi.Gradings

  def index(conn, %{"tournament_id" => tournament_id}) do
    data = Gradings.list_sessions_by_tournament(tournament_id) |> Enum.map(&serialize/1)
    json(conn, %{data: data})
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
      written_carryover_months: session.written_carryover_months
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
