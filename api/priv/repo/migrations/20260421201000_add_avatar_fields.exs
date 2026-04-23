defmodule ZanshinApi.Repo.Migrations.AddAvatarFields do
  use Ecto.Migration

  def change do
    alter table(:competitors) do
      add :avatar_url, :text
    end

    alter table(:teams) do
      add :avatar_url, :text
    end
  end
end
