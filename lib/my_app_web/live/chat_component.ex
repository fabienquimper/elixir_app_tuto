defmodule MyAppWeb.ChatComponent do
  use MyAppWeb, :live_component
  alias MyApp.ChatGPT

  @impl true
  def update(assigns, socket) do
    if reply = assigns[:reply_from_ai] do
      IO.puts("--> 4. COMPONENT FINALLY UPDATED !")
      new_messages = socket.assigns.messages ++ [%{role: "assistant", content: reply}]
      {:ok, assign(socket, messages: new_messages, loading: false)}
    else
      {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:messages, fn -> [] end)
      |> assign_new(:loading, fn -> false end)}
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    message = String.trim(message)
    if message == "" do
      {:noreply, socket}
    else
      IO.puts("--> 1. RECEIVE EVENT : #{message}")
      new_messages = socket.assigns.messages ++ [%{role: "user", content: message}]

      # We retrieve the parent PID (Index) BEFORE launching the Task
      parent_pid = self()

      # We launch the task but ignore its return for handle_event
      Task.start(fn ->
        IO.puts("--> 2. ENVOI À LM STUDIO...")
        reply = case ChatGPT.ask_question(message) do
          {:ok, content} -> content
          {:error, reason} -> "Error: #{reason}"
        end

        # We send to the parent (Index) which will do the send_update
        send(parent_pid, {:llm_reply_for_component, reply})
      end)

      # HERE : We return the tuple expected by Phoenix
      {:noreply, assign(socket, messages: new_messages, loading: true)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white border-2 border-blue-100 rounded-xl shadow-md mb-8 overflow-hidden text-black">
      <div class="p-3 border-b bg-blue-50 font-semibold text-blue-800">
        Timeline Assistant
      </div>

      <div class="h-64 overflow-y-auto p-4 space-y-4 bg-white" id="chat-messages">
        <%= for {msg, i} <- Enum.with_index(@messages) do %>
          <div id={"msg-#{i}"} class={"flex #{if msg.role == "user", do: "justify-end", else: "justify-start"}"}>
            <div class={"max-w-[85%] rounded-2xl p-3 text-sm #{if msg.role == "user", do: "bg-blue-600 text-white", else: "bg-gray-100 text-black border border-gray-200"}"}>
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
        <input name="message" placeholder="Ask a question..." autocomplete="off"
          class="flex-1 rounded-lg border-gray-300 bg-white px-4 py-2 text-black" />
        <button type="submit" disabled={@loading} class="px-5 py-2 bg-blue-600 text-white rounded-lg">
          Send
        </button>
      </form>
    </div>
    """
  end
end
