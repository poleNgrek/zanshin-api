defmodule ZanshinApi.Analytics.Projector do
  @moduledoc """
  Behaviour for analytics projectors that transform domain events into read models.
  """

  alias ZanshinApi.Events.DomainEvent

  @callback project(DomainEvent.t(), keyword()) :: :ok | {:error, term()}
end
