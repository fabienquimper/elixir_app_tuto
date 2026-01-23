defmodule MyApp.Post.Timeline do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post" do
    field :posts, :string
    field :username, :string
    field :body, :string
    field :likes_count, :integer
    field :reposts_count, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(timeline, attrs) do
    timeline
    |> cast(attrs, [:posts, :username, :body, :likes_count, :reposts_count])
    |> validate_required([:posts, :username, :body, :likes_count, :reposts_count])
  end
end
