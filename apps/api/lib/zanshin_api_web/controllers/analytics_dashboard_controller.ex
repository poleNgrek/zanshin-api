defmodule ZanshinApiWeb.AnalyticsDashboardController do
  use ZanshinApiWeb, :controller

  alias ZanshinApi.Analytics

  def event_feed(conn, params) do
    with :ok <- authorize_read(conn),
         {:ok, payload} <- Analytics.dashboard_event_feed(params) do
      json(conn, %{data: payload})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, :tournament_id_required} ->
        conn |> put_status(:bad_request) |> json(%{error: "tournament_id_required"})

      {:error, :invalid_datetime_filter} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_datetime_filter"})

      {:error, :invalid_time_window} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_time_window"})
    end
  end

  def match_state_overview(conn, params) do
    with :ok <- authorize_read(conn),
         {:ok, payload} <- Analytics.match_state_overview(params) do
      json(conn, %{data: payload})
    else
      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

      {:error, :tournament_id_required} ->
        conn |> put_status(:bad_request) |> json(%{error: "tournament_id_required"})
    end
  end

  defp authorize_read(conn) do
    case conn.assigns[:current_role] do
      :admin -> :ok
      _ -> {:error, :forbidden}
    end
  end
end
