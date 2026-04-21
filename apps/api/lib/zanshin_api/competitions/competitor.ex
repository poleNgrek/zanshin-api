defmodule ZanshinApi.Competitions.Competitor do
  @moduledoc "Competitor entity for tournament and grading participation."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "competitors" do
    field :display_name, :string
    field :federation_id, :string
    field :birth_date, :date

    timestamps(type: :utc_datetime)
  end

  def changeset(competitor, attrs) do
    competitor
    |> cast(attrs, [:display_name, :federation_id, :birth_date])
    |> validate_required([:display_name])
    |> validate_length(:display_name, min: 2, max: 120)
    |> unique_constraint(:federation_id)
  end
end
