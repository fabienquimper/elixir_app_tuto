defmodule MyAppWeb.TimelineLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Post

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Post
        <:actions>
          <.button variant="primary" navigate={~p"/post/new"}>
            <.icon name="hero-plus" /> New Timeline
          </.button>
        </:actions>
      </.header>

      <.table
        id="post"
        rows={@streams.post}
        row_click={fn {_id, timeline} -> JS.navigate(~p"/post/#{timeline}") end}
      >
        <:col :let={{_id, timeline}} label="Posts">{timeline.posts}</:col>
        <:col :let={{_id, timeline}} label="Username">{timeline.username}</:col>
        <:col :let={{_id, timeline}} label="Body">{timeline.body}</:col>
        <:col :let={{_id, timeline}} label="Likes count">{timeline.likes_count}</:col>
        <:col :let={{_id, timeline}} label="Reposts count">{timeline.reposts_count}</:col>
        <:action :let={{_id, timeline}}>
          <div class="sr-only">
            <.link navigate={~p"/post/#{timeline}"}>Show</.link>
          </div>
          <.link navigate={~p"/post/#{timeline}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, timeline}}>
          <.link
            phx-click={JS.push("delete", value: %{id: timeline.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Post")
     |> stream(:post, list_post())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    timeline = Post.get_timeline!(id)
    {:ok, _} = Post.delete_timeline(timeline)

    {:noreply, stream_delete(socket, :post, timeline)}
  end

  defp list_post() do
    Post.list_post()
  end
end
