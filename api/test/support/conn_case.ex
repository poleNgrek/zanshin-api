defmodule ZanshinApiWeb.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint ZanshinApiWeb.Endpoint
      import Plug.Conn
      import Phoenix.ConnTest
      import ZanshinApi.DataCase
      alias ZanshinApi.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ZanshinApi.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ZanshinApi.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
