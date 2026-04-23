defmodule ZanshinApi.Competitions.Competitor do
  @moduledoc "Competitor entity for tournament and grading participation."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @stances [:chudan, :jodan_left, :jodan_right, :nito, :gedan, :hasso, :waki, :other]
  @grade_types [:kyu, :dan]
  @grade_titles [:none, :renshi, :kyoshi, :hanshi]

  schema "competitors" do
    field :display_name, :string
    field :federation_id, :string
    field :birth_date, :date
    field :avatar_url, :string
    field :preferred_stance, Ecto.Enum, values: @stances
    field :grade_value, :integer
    field :grade_type, Ecto.Enum, values: @grade_types
    field :grade_title, Ecto.Enum, values: @grade_titles, default: :none

    timestamps(type: :utc_datetime)
  end

  def changeset(competitor, attrs) do
    attrs = normalize_avatar_attrs(attrs)

    competitor
    |> cast(attrs, [
      :display_name,
      :federation_id,
      :birth_date,
      :avatar_url,
      :preferred_stance,
      :grade_value,
      :grade_type,
      :grade_title
    ])
    |> validate_required([:display_name])
    |> validate_length(:display_name, min: 2, max: 120)
    |> validate_number(:grade_value, greater_than: 0)
    |> validate_grade_pair()
    |> unique_constraint(:federation_id)
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

  defp validate_grade_pair(changeset) do
    grade_value = get_field(changeset, :grade_value)
    grade_type = get_field(changeset, :grade_type)

    cond do
      is_nil(grade_value) and is_nil(grade_type) ->
        changeset

      is_integer(grade_value) and not is_nil(grade_type) ->
        changeset

      true ->
        add_error(changeset, :grade_type, "must be present together with grade_value")
    end
  end
end
