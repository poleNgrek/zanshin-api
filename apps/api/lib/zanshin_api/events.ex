defmodule ZanshinApi.Events do
  @moduledoc """
  Domain events context.

  Canonical envelope:
  - event_type
  - event_version
  - aggregate_type
  - aggregate_id
  - occurred_at
  - actor_role
  - payload
  - source
  - correlation_id
  - causation_id
  """

  import Ecto.Query, warn: false

  alias ZanshinApi.Events.DomainEvent
  alias ZanshinApi.Repo

  def new_domain_event_changeset(attrs) do
    DomainEvent.changeset(%DomainEvent{}, attrs)
  end

  def create_domain_event(attrs) do
    attrs
    |> new_domain_event_changeset()
    |> Repo.insert()
  end

  def list_unprocessed_events(limit \\ 100) do
    DomainEvent
    |> where([event], is_nil(event.processed_at))
    |> order_by([event], asc: event.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def mark_processed(event_id) do
    case Repo.get(DomainEvent, event_id) do
      nil ->
        {:error, :domain_event_not_found}

      event ->
        event
        |> DomainEvent.changeset(%{processed_at: DateTime.utc_now()})
        |> Repo.update()
    end
  end

  def list_events_for_aggregate(aggregate_type, aggregate_id) do
    DomainEvent
    |> where(
      [event],
      event.aggregate_type == ^to_string(aggregate_type) and event.aggregate_id == ^aggregate_id
    )
    |> order_by([event], asc: event.inserted_at)
    |> Repo.all()
  end
end
