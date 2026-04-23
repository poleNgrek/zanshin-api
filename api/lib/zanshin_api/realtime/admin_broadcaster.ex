defmodule ZanshinApi.Realtime.AdminBroadcaster do
  @moduledoc false

  @spec broadcast(String.t(), map()) :: :ok
  def broadcast(event_name, payload) when is_binary(event_name) and is_map(payload) do
    payload = Map.put_new(payload, :occurred_at, DateTime.utc_now() |> DateTime.truncate(:second))

    ZanshinApiWeb.Endpoint.broadcast("admin:all", event_name, payload)

    payload
    |> topic_scopes()
    |> Enum.each(fn topic -> ZanshinApiWeb.Endpoint.broadcast(topic, event_name, payload) end)

    :ok
  end

  defp topic_scopes(payload) do
    [
      {"admin:tournament:",
       Map.get(payload, :tournament_id) || Map.get(payload, "tournament_id")},
      {"admin:division:", Map.get(payload, :division_id) || Map.get(payload, "division_id")},
      {"admin:team:", Map.get(payload, :team_id) || Map.get(payload, "team_id")},
      {"admin:grading_session:",
       Map.get(payload, :grading_session_id) || Map.get(payload, "grading_session_id")},
      {"admin:grading_result:",
       Map.get(payload, :grading_result_id) || Map.get(payload, "grading_result_id")}
    ]
    |> Enum.reject(fn {_prefix, id} -> is_nil(id) end)
    |> Enum.map(fn {prefix, id} -> prefix <> to_string(id) end)
  end
end
