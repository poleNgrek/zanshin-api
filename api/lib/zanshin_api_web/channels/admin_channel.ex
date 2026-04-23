defmodule ZanshinApiWeb.AdminChannel do
  use ZanshinApiWeb, :channel

  @impl true
  def join("admin:tournament:" <> tournament_id, _payload, socket) do
    {:ok, assign(socket, :tournament_id, tournament_id)}
  end

  def join("admin:division:" <> division_id, _payload, socket) do
    {:ok, assign(socket, :division_id, division_id)}
  end

  def join("admin:team:" <> team_id, _payload, socket) do
    {:ok, assign(socket, :team_id, team_id)}
  end

  def join("admin:grading_session:" <> session_id, _payload, socket) do
    {:ok, assign(socket, :grading_session_id, session_id)}
  end

  def join("admin:grading_result:" <> result_id, _payload, socket) do
    {:ok, assign(socket, :grading_result_id, result_id)}
  end

  def join("admin:all", _payload, socket) do
    {:ok, socket}
  end

  def join(_topic, _payload, _socket), do: {:error, %{reason: "unauthorized"}}
end
