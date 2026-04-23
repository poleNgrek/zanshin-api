defmodule ZanshinApi.Officials.Shinpan do
  @moduledoc "Shinpan (referee) model."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shinpans" do
    field :display_name, :string
    field :federation_id, :string

    belongs_to :tournament, ZanshinApi.Competitions.Tournament
    has_many :assignments, ZanshinApi.Competitions.ShinpanAssignment

    timestamps(type: :utc_datetime)
  end

  def changeset(shinpan, attrs) do
    shinpan
    |> cast(attrs, [:display_name, :federation_id, :tournament_id])
    |> validate_required([:display_name])
    |> foreign_key_constraint(:tournament_id)
    |> unique_constraint(:federation_id)
  end
end
