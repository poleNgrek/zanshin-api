defmodule ZanshinApi.Grading.GradingSession do
  @moduledoc "Kyu/Dan grading session model."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "grading_sessions" do
    field :name, :string
    field :held_on, :date

    belongs_to :tournament, ZanshinApi.Competitions.Tournament
    has_many :results, ZanshinApi.Grading.GradingResult

    timestamps(type: :utc_datetime)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:name, :held_on, :tournament_id])
    |> validate_required([:name, :tournament_id])
    |> foreign_key_constraint(:tournament_id)
  end
end
