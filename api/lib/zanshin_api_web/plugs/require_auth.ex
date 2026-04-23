defmodule ZanshinApiWeb.Plugs.RequireAuth do
  @moduledoc """
  Enforces Bearer JWT authentication and assigns actor context.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias ZanshinApi.Auth.TokenVerifier

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- bearer_token(conn),
         {:ok, actor} <- TokenVerifier.verify_token(token) do
      conn
      |> assign(:current_actor, actor)
      |> assign(:current_role, actor.role)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
        |> halt()
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when byte_size(token) > 0 -> {:ok, token}
      _ -> {:error, :missing_bearer_token}
    end
  end
end
