defmodule MyApp.Post.Timeline do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post" do
    field :posts, :string
    field :username, :string, default: "fabien"
    field :body, :string
    field :likes_count, :integer, default: 0
    field :reposts_count, :integer,   default: 0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(timeline, attrs) do
    timeline
    # |> cast(attrs, [:posts, :body])
    # |> cast(attrs, [:posts, :body, :username, :likes_count, :reposts_count])
    # |> validate_required([:posts, :body])
    # |> cast(attrs, [:posts, :body, :username])
    |> cast(attrs, [:body])
    |> validate_required([:body]) # Laisse juste le body pour l'instant
    |> validate_length(:body, min: 10, max: 250)
  end
end
