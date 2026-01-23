defmodule MyApp.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def change do
    create table(:post) do
      add :posts, :string
      add :username, :string
      add :body, :string
      add :likes_count, :integer
      add :reposts_count, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
