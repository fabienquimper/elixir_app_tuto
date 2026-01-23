defmodule MyApp.PostFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MyApp.Post` context.
  """

  @doc """
  Generate a timeline.
  """
  def timeline_fixture(attrs \\ %{}) do
    {:ok, timeline} =
      attrs
      |> Enum.into(%{
        body: "some body",
        likes_count: 42,
        posts: "some posts",
        reposts_count: 42,
        username: "some username"
      })
      |> MyApp.Post.create_timeline()

    timeline
  end
end
