defmodule ZanshinApi.Competitions.Division do
  @moduledoc "Division entity scoped under a tournament."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @formats [:bracket, :swiss, :round_robin, :team]

  schema "divisions" do
    field :name, :string
    field :format, Ecto.Enum, values: @formats

    belongs_to :tournament, ZanshinApi.Competitions.Tournament

    timestamps(type: :utc_datetime)
  end

  def changeset(division, attrs) do
    division
    |> cast(attrs, [:name, :format, :tournament_id])
    |> validate_required([:name, :format, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end
