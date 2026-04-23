defmodule ZanshinApiWeb.AnalyticsMatchSummaryController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Analytics

  def index(conn, params) do
    with :ok <- authorize_read(conn),
         {:ok, summary} <- Analytics.match_summary(params) do
      json(conn, %{data: summary})
    else
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})

      {:error, :tournament_id_required} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "tournament_id_required"})

      {:error, :invalid_datetime_filter} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_datetime_filter"})

      {:error, :invalid_time_window} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_time_window"})
    end
  end

  defp authorize_read(conn) do
    case conn.assigns[:current_role] do
      :admin -> :ok
      _ -> {:error, :forbidden}
    end
  end
end
