defmodule ZanshinApiWeb.MatchChannel do
  use ZanshinApiWeb, :channel

  @impl true
  def join("matches:tournament:" <> tournament_id, _payload, socket) do
    {:ok, assign(socket, :tournament_id, tournament_id)}
  end

  def join("matches:match:" <> match_id, _payload, socket) do
    {:ok, assign(socket, :match_id, match_id)}
  end

  def join("matches:all", _payload, socket) do
    {:ok, socket}
  end

  def join(_topic, _payload, _socket), do: {:error, %{reason: "unauthorized"}}
end
