defmodule MyAppWeb.ChatComponent do
  use MyAppWeb, :live_component
  alias MyApp.ChatGPT

  @impl true
  def update(assigns, socket) do
    socket =
      if reply = assigns[:reply_from_ai] do
        new_messages = socket.assigns.messages ++ [%{role: "assistant", content: reply}]
        assign(socket, messages: new_messages, loading: false)
      else
        socket
        |> assign(assigns)
        |> assign_new(:messages, fn -> [] end)
        |> assign_new(:loading, fn -> false end)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    message = String.trim(message)
    if message == "" do
      {:noreply, socket}
    else
      new_messages = socket.assigns.messages ++ [%{role: "user", content: message}]
      myself = socket.assigns.myself

      Task.start(fn ->
        reply = case ChatGPT.ask_question(message) do
          {:ok, content} -> content
          {:error, reason} -> "Error: #{reason}"
        end
        send_update(myself, reply_from_ai: reply)
      end)

      {:noreply, assign(socket, messages: new_messages, loading: true)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white border-2 border-blue-100 rounded-xl shadow-md mb-8 overflow-hidden text-black">
      <div class="p-3 border-b bg-blue-50 font-semibold text-blue-800 flex items-center gap-2">
        <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
        Timeline Assistant
      </div>

      <div class="h-64 overflow-y-auto p-4 space-y-4 bg-white" id="chat-messages">
        <%= for msg <- @messages do %>
          <div class={"flex #{if msg.role == "user", do: "justify-end", else: "justify-start"}"}>
            <div class={"max-w-[85%] rounded-2xl p-3 text-sm shadow-sm #{if msg.role == "user", do: "bg-blue-600 text-white", else: "bg-gray-100 text-black border border-gray-200"}"}>
              <%= msg.content %>
            </div>
          </div>
        <% end %>

        <%= if @loading do %>
          <div class="flex justify-start animate-pulse">
            <div class="bg-gray-100 text-gray-500 text-xs italic p-2 rounded-lg">AI is thinking...</div>
          </div>
        <% end %>
      </div>

      <form phx-submit="send_message" phx-target={@myself} class="p-4 border-t bg-gray-50 flex gap-2">
        <input
          name="message"
          placeholder="Ask a question..."
          class="flex-1 rounded-lg border-gray-300 bg-white px-4 py-2 text-black focus:border-blue-500 focus:ring-blue-500"
          autocomplete="off"
        />
        <button type="submit" disabled={@loading} class="px-5 py-2 bg-blue-600 text-white font-medium rounded-lg disabled:bg-gray-400">
          Send
        </button>
      </form>
    </div>
    """
  end
end
