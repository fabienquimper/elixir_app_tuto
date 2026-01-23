defmodule MyAppWeb.TimelineLive.Form do
  use MyAppWeb, :live_view

  alias MyApp.Post
  alias MyApp.Post.Timeline

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage timeline records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="timeline-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:posts]} type="text" label="Posts" />
        <.input field={@form[:username]} type="text" label="Username" />
        <.input field={@form[:body]} type="text" label="Body" />
        <.input field={@form[:likes_count]} type="number" label="Likes count" />
        <.input field={@form[:reposts_count]} type="number" label="Reposts count" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Timeline</.button>
          <.button navigate={return_path(@return_to, @timeline)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    timeline = Post.get_timeline!(id)

    socket
    |> assign(:page_title, "Edit Timeline")
    |> assign(:timeline, timeline)
    |> assign(:form, to_form(Post.change_timeline(timeline)))
  end

  defp apply_action(socket, :new, _params) do
    timeline = %Timeline{}

    socket
    |> assign(:page_title, "New Timeline")
    |> assign(:timeline, timeline)
    |> assign(:form, to_form(Post.change_timeline(timeline)))
  end

  @impl true
  def handle_event("validate", %{"timeline" => timeline_params}, socket) do
    changeset = Post.change_timeline(socket.assigns.timeline, timeline_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"timeline" => timeline_params}, socket) do
    save_timeline(socket, socket.assigns.live_action, timeline_params)
  end

  defp save_timeline(socket, :edit, timeline_params) do
    case Post.update_timeline(socket.assigns.timeline, timeline_params) do
      {:ok, timeline} ->
        {:noreply,
         socket
         |> put_flash(:info, "Timeline updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, timeline))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_timeline(socket, :new, timeline_params) do
    case Post.create_timeline(timeline_params) do
      {:ok, timeline} ->
        {:noreply,
         socket
         |> put_flash(:info, "Timeline created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, timeline))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _timeline), do: ~p"/post"
  defp return_path("show", timeline), do: ~p"/post/#{timeline}"
end
