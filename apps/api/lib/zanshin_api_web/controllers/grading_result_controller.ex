defmodule ZanshinApiWeb.GradingResultController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Grading.{GradingNote, GradingResult, GradingVote}
  alias ZanshinApi.Gradings

  def index(conn, %{"id" => session_id}) do
    data = Gradings.list_results_by_session(session_id) |> Enum.map(&serialize_result/1)
    json(conn, %{data: data})
  end

  def create(conn, %{"id" => session_id} = params) do
    with :ok <- authorize_write(conn),
         {:ok, result} <- Gradings.create_result(session_id, params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_result(result)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_grading_result_payload", details: changeset_errors(changeset)})
    end
  end

  def create_vote(conn, %{"id" => result_id} = params) do
    with :ok <- authorize_write(conn),
         {:ok, vote} <- Gradings.create_vote(result_id, params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_vote(vote)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_grading_vote_payload", details: changeset_errors(changeset)})
    end
  end

  def votes(conn, %{"id" => result_id}) do
    data = Gradings.list_votes(result_id) |> Enum.map(&serialize_vote/1)
    json(conn, %{data: data})
  end

  def create_note(conn, %{"id" => result_id} = params) do
    with :ok <- authorize_write(conn),
         {:ok, note} <- Gradings.create_note(result_id, params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_note(note)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_grading_note_payload", details: changeset_errors(changeset)})
    end
  end

  def notes(conn, %{"id" => result_id}) do
    data = Gradings.list_notes(result_id) |> Enum.map(&serialize_note/1)
    json(conn, %{data: data})
  end

  defp serialize_result(%GradingResult{} = result) do
    %{
      id: result.id,
      grading_session_id: result.grading_session_id,
      competitor_id: result.competitor_id,
      target_grade: result.target_grade,
      final_result: to_string(result.final_result),
      jitsugi_result: to_string(result.jitsugi_result),
      kata_result: to_string(result.kata_result),
      written_result: to_string(result.written_result),
      carryover_until: result.carryover_until,
      declared_stance:
        if(result.declared_stance, do: to_string(result.declared_stance), else: nil)
    }
  end

  defp serialize_vote(%GradingVote{} = vote) do
    %{
      id: vote.id,
      grading_result_id: vote.grading_result_id,
      examiner_id: vote.examiner_id,
      part: to_string(vote.part),
      decision: to_string(vote.decision),
      note: vote.note
    }
  end

  defp serialize_note(%GradingNote{} = note) do
    %{
      id: note.id,
      grading_result_id: note.grading_result_id,
      examiner_id: note.examiner_id,
      part: if(note.part, do: to_string(note.part), else: nil),
      note: note.note
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
