defmodule ZanshinApiWeb.HealthController do
  use ZanshinApiWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", service: "zanshin_api"})
  end
end
