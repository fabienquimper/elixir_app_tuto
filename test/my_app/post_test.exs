defmodule MyApp.PostTest do
  use MyApp.DataCase

  alias MyApp.Post

  describe "post" do
    alias MyApp.Post.Timeline

    import MyApp.PostFixtures

    @invalid_attrs %{body: nil, username: nil, posts: nil, likes_count: nil, reposts_count: nil}

    test "list_post/0 returns all post" do
      timeline = timeline_fixture()
      assert Post.list_post() == [timeline]
    end

    test "get_timeline!/1 returns the timeline with given id" do
      timeline = timeline_fixture()
      assert Post.get_timeline!(timeline.id) == timeline
    end

    test "create_timeline/1 with valid data creates a timeline" do
      valid_attrs = %{body: "some body", username: "some username", posts: "some posts", likes_count: 42, reposts_count: 42}

      assert {:ok, %Timeline{} = timeline} = Post.create_timeline(valid_attrs)
      assert timeline.body == "some body"
      assert timeline.username == "some username"
      assert timeline.posts == "some posts"
      assert timeline.likes_count == 42
      assert timeline.reposts_count == 42
    end

    test "create_timeline/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Post.create_timeline(@invalid_attrs)
    end

    test "update_timeline/2 with valid data updates the timeline" do
      timeline = timeline_fixture()
      update_attrs = %{body: "some updated body", username: "some updated username", posts: "some updated posts", likes_count: 43, reposts_count: 43}

      assert {:ok, %Timeline{} = timeline} = Post.update_timeline(timeline, update_attrs)
      assert timeline.body == "some updated body"
      assert timeline.username == "some updated username"
      assert timeline.posts == "some updated posts"
      assert timeline.likes_count == 43
      assert timeline.reposts_count == 43
    end

    test "update_timeline/2 with invalid data returns error changeset" do
      timeline = timeline_fixture()
      assert {:error, %Ecto.Changeset{}} = Post.update_timeline(timeline, @invalid_attrs)
      assert timeline == Post.get_timeline!(timeline.id)
    end

    test "delete_timeline/1 deletes the timeline" do
      timeline = timeline_fixture()
      assert {:ok, %Timeline{}} = Post.delete_timeline(timeline)
      assert_raise Ecto.NoResultsError, fn -> Post.get_timeline!(timeline.id) end
    end

    test "change_timeline/1 returns a timeline changeset" do
      timeline = timeline_fixture()
      assert %Ecto.Changeset{} = Post.change_timeline(timeline)
    end
  end
end
