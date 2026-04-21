defmodule ZanshinApi.Teams.Team do
  @moduledoc "Team roster root for team-format divisions."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "teams" do
    field :name, :string
    field :avatar_url, :string

    belongs_to :division, ZanshinApi.Competitions.Division
    has_many :members, ZanshinApi.Teams.TeamMember

    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    attrs = normalize_avatar_attrs(attrs)

    team
    |> cast(attrs, [:name, :division_id, :avatar_url])
    |> validate_required([:name, :division_id])
    |> validate_length(:name, min: 2, max: 120)
    |> foreign_key_constraint(:division_id)
  end

  defp normalize_avatar_attrs(%{} = attrs) do
    avatar = Map.get(attrs, "avatar_url") || Map.get(attrs, :avatar_url)
    photo = Map.get(attrs, "photo_url") || Map.get(attrs, :photo_url)

    cond do
      is_binary(avatar) and byte_size(avatar) > 0 -> attrs
      is_binary(photo) and byte_size(photo) > 0 -> Map.put(attrs, "avatar_url", photo)
      true -> attrs
    end
  end

  defp normalize_avatar_attrs(attrs), do: attrs
end
