defmodule MyAppWeb.TimelineLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyApp.PostFixtures

  @create_attrs %{body: "some body", username: "some username", posts: "some posts", likes_count: 42, reposts_count: 42}
  @update_attrs %{body: "some updated body", username: "some updated username", posts: "some updated posts", likes_count: 43, reposts_count: 43}
  @invalid_attrs %{body: nil, username: nil, posts: nil, likes_count: nil, reposts_count: nil}
  defp create_timeline(_) do
    timeline = timeline_fixture()

    %{timeline: timeline}
  end

  describe "Index" do
    setup [:create_timeline]

    test "lists all post", %{conn: conn, timeline: timeline} do
      {:ok, _index_live, html} = live(conn, ~p"/post")

      assert html =~ "Listing Post"
      assert html =~ timeline.posts
    end

    test "saves new timeline", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/post")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Timeline")
               |> render_click()
               |> follow_redirect(conn, ~p"/post/new")

      assert render(form_live) =~ "New Timeline"

      assert form_live
             |> form("#timeline-form", timeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#timeline-form", timeline: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/post")

      html = render(index_live)
      assert html =~ "Timeline created successfully"
      assert html =~ "some posts"
    end

    test "updates timeline in listing", %{conn: conn, timeline: timeline} do
      {:ok, index_live, _html} = live(conn, ~p"/post")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#post-#{timeline.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/post/#{timeline}/edit")

      assert render(form_live) =~ "Edit Timeline"

      assert form_live
             |> form("#timeline-form", timeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#timeline-form", timeline: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/post")

      html = render(index_live)
      assert html =~ "Timeline updated successfully"
      assert html =~ "some updated posts"
    end

    test "deletes timeline in listing", %{conn: conn, timeline: timeline} do
      {:ok, index_live, _html} = live(conn, ~p"/post")

      assert index_live |> element("#post-#{timeline.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#post-#{timeline.id}")
    end
  end

  describe "Show" do
    setup [:create_timeline]

    test "displays timeline", %{conn: conn, timeline: timeline} do
      {:ok, _show_live, html} = live(conn, ~p"/post/#{timeline}")

      assert html =~ "Show Timeline"
      assert html =~ timeline.posts
    end

    test "updates timeline and returns to show", %{conn: conn, timeline: timeline} do
      {:ok, show_live, _html} = live(conn, ~p"/post/#{timeline}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/post/#{timeline}/edit?return_to=show")

      assert render(form_live) =~ "Edit Timeline"

      assert form_live
             |> form("#timeline-form", timeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#timeline-form", timeline: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/post/#{timeline}")

      html = render(show_live)
      assert html =~ "Timeline updated successfully"
      assert html =~ "some updated posts"
    end
  end
end
