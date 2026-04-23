defmodule ZanshinApiWeb.GradingExaminerController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Grading.{GradingExaminer, GradingPanelAssignment}
  alias ZanshinApi.Gradings

  def index(conn, _params) do
    data = Gradings.list_examiners() |> Enum.map(&serialize_examiner/1)
    json(conn, %{data: data})
  end

  def create(conn, params) do
    with :ok <- authorize_write(conn),
         {:ok, examiner} <- Gradings.create_examiner(params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_examiner(examiner)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "invalid_grading_examiner_payload",
          details: changeset_errors(changeset)
        })
    end
  end

  def assign(conn, %{"id" => session_id} = params) do
    with :ok <- authorize_write(conn),
         {:ok, assignment} <- Gradings.assign_examiner_to_session(session_id, params) do
      conn
      |> put_status(:created)
      |> json(%{data: serialize_assignment(assignment)})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "invalid_grading_panel_assignment_payload",
          details: changeset_errors(changeset)
        })
    end
  end

  def panel(conn, %{"id" => session_id}) do
    data = Gradings.list_panel_assignments(session_id) |> Enum.map(&serialize_assignment/1)
    json(conn, %{data: data})
  end

  defp serialize_examiner(%GradingExaminer{} = examiner) do
    %{
      id: examiner.id,
      display_name: examiner.display_name,
      federation_id: examiner.federation_id,
      federation_name: examiner.federation_name,
      grade: examiner.grade,
      title: examiner.title
    }
  end

  defp serialize_assignment(%GradingPanelAssignment{} = assignment) do
    %{
      id: assignment.id,
      grading_session_id: assignment.grading_session_id,
      examiner_id: assignment.examiner_id,
      role: to_string(assignment.role)
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
