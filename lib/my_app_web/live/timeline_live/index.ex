defmodule MyAppWeb.TimelineLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Post

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Timeline
        <:actions>
          <.button variant="primary" navigate={~p"/post/new"}>
            <.icon name="hero-plus" /> New Post
          </.button>
        </:actions>
      </.header>

      <div class="max-w-2xl mx-auto py-8">


        <div id="posts" phx-update="stream">
          <%= for {dom_id, post} <- @streams.post do %>
            <.live_component
              module={MyAppWeb.TimelineLive.PostComponent}
              id={dom_id}
              post={post}
            />
          <% end %>
        </div>
      </div>

    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Post.subscribe()
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

  @impl true
  def handle_info({:timeline_created, timeline}, socket) do
      # {:noreply, stream_insert(socket, :post, timeline, at: 0)}
    # {:noreply, update(socket, :posts, fn posts -> [timeline | posts] end)}

    # stream_insert dit à LiveView : "Envoie juste ce petit bout de HTML au navigateur"
    # at: 0 le place tout en haut de la liste (comme sur Twitter)
    {:noreply, stream_insert(socket, :post, timeline, at: 0)}
  end

  defp list_post() do
    Post.list_post()
  end
end
