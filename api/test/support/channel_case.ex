defmodule ZanshinApiWeb.ChannelCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import ZanshinApi.DataCase
      import ZanshinApiWeb.ChannelCase

      @endpoint ZanshinApiWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ZanshinApi.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ZanshinApi.Repo, {:shared, self()})
    end

    :ok
  end
end
