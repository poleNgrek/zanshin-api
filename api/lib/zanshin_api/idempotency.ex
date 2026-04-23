defmodule ZanshinApi.Idempotency do
  @moduledoc """
  Stores and replays idempotent command responses.
  """

  alias ZanshinApi.Idempotency.RequestKey
  alias ZanshinApi.Repo

  def reserve(attrs) do
    %RequestKey{}
    |> RequestKey.create_changeset(attrs)
    |> Repo.insert()
  end

  def get(key, endpoint, actor_subject) do
    Repo.get_by(RequestKey, key: key, endpoint: endpoint, actor_subject: actor_subject)
  end

  def complete(%RequestKey{} = request_key, status, response_body) do
    request_key
    |> RequestKey.complete_changeset(%{
      response_status: status,
      response_body: response_body,
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  def mark_replayed(%RequestKey{} = request_key) do
    request_key
    |> RequestKey.replayed_changeset()
    |> Repo.update()
  end
end
