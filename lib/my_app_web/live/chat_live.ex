defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  alias MyApp.ChatGPT

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, messages: [], input: "", loading: false)}
  end

  @impl true
  def handle_event("update_input", %{"message" => value}, socket) do
    {:noreply, assign(socket, input: value)}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    message = String.trim(message)

    if message == "" do
      {:noreply, socket}
    else
      # Append user message immediately
      messages = socket.assigns.messages ++ [%{role: "user", content: message}]

      socket = assign(socket, messages: messages, input: "", loading: true)

      # Call the LLM asynchronously to avoid blocking the LiveView
      self_pid = self()
      Task.start(fn ->
        reply =
          case ChatGPT.ask_question(message) do
            {:ok, content} -> content
            {:error, reason} -> "Error: #{reason}"
          end

        send(self_pid, {:llm_reply, reply})
      end)

      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:llm_reply, reply}, socket) do
    messages = socket.assigns.messages ++ [%{role: "assistant", content: reply}]
    {:noreply, assign(socket, messages: messages, loading: false)}
  end

  defp render_message(assigns) do
    ~H"""
    <div class={"msg " <> @role}>
      <div class="bubble"> <%= @content %> </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="chat-page">
      <div class="left-panel">
        <h3 class="panel-title">LLM Chat</h3>
        <div id="messages" class="messages">
          <%= for msg <- @messages do %>
            <%= render_message(msg) %>
          <% end %>
        </div>
        <form phx-submit="send_message" class="input-form">
          <input
            name="message"
            value={@input}
            phx-change="update_input"
            phx-debounce="250"
            placeholder="Type a message..."
            class="chat-input"
          />
          <button type="submit" class="send-btn" disabled={@loading}>Send</button>
        </form>
      </div>

      <div class="right-panel">
        <h3 class="panel-title">Context / Controls</h3>
        <p>Put conversation list, settings, or other UI here.</p>
      </div>
    </div>
    """
  end
end
