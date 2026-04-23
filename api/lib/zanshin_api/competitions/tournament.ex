defmodule ZanshinApi.Competitions.Tournament do
  @moduledoc "Tournament root entity."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tournaments" do
    field :name, :string
    field :location, :string
    field :starts_on, :date

    has_many :divisions, ZanshinApi.Competitions.Division

    timestamps(type: :utc_datetime)
  end

  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :location, :starts_on])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 120)
  end
end
