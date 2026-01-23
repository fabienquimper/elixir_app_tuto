defmodule MyAppWeb.TimelineLive.Show do
  use MyAppWeb, :live_view

  alias MyApp.Post

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Timeline {@timeline.id}
        <:subtitle>This is a timeline record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/post"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/post/#{@timeline}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit timeline
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Posts">{@timeline.posts}</:item>
        <:item title="Username">{@timeline.username}</:item>
        <:item title="Body">{@timeline.body}</:item>
        <:item title="Likes count">{@timeline.likes_count}</:item>
        <:item title="Reposts count">{@timeline.reposts_count}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Timeline")
     |> assign(:timeline, Post.get_timeline!(id))}
  end
end
