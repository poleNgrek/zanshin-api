defmodule ZanshinApi.Competitions.Shiaijo do
  @moduledoc "Shiaijo (competition area) model."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shiaijos" do
    field :name, :string

    belongs_to :tournament, ZanshinApi.Competitions.Tournament
    has_many :assignments, ZanshinApi.Competitions.ShinpanAssignment

    timestamps(type: :utc_datetime)
  end

  def changeset(shiaijo, attrs) do
    shiaijo
    |> cast(attrs, [:name, :tournament_id])
    |> validate_required([:name, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end
