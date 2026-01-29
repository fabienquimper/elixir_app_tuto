defmodule MyApp.ChatGPT do
  @lm_url "http://192.168.1.66:1234/v1/chat/completions"

  # On ajoute '2>/dev/null' pour masquer les erreurs Docker et on utilisera un filtre ensuite
  # Docker command is constructed from configuration at runtime (see mcp_docker_cmd/0)

  def ask_question(prompt) do
    # On récupère les outils et on vérifie qu'ils ne sont pas vides
    tools = case get_all_mcp_tools() do
      [] -> fallback_tools() # Si Docker échoue, on force les définitions
      list -> list
    end

    messages = [
      %{role: "system", content: """
      Tu es un assistant technique utile.
    - Si l'utilisateur te demande une action (créer, lister, supprimer un fichier), utilise l'outil approprié.
    - Si l'utilisateur te pose une question générale, réponds directement par du texte sans utiliser d'outil.
    - Ne génère jamais de balises comme <|channel|> ou <|message|>.
    - Réponds de manière concise.
        """},
      %{role: "user", content: prompt}
    ]

    perform_request(messages, tools)
  end

  defp perform_request(messages, tools) do
    body = %{
      model: "openai/gpt-oss-20b",
      messages: messages,
      tools: tools, # ICI : On s'assure que ce n'est PAS []
      tool_choice: "auto",
      temperature: 0
    }

    case Req.post(@lm_url, json: body, receive_timeout: 300_000) do
      {:ok, %{status: 200, body: response}} ->
        choice = List.first(response["choices"])
        message = choice["message"]

        if choice["finish_reason"] == "tool_calls" and message["tool_calls"] != nil do
          new_history = handle_tool_calls(message, messages)
          perform_request(new_history, tools)
        else
          # Si l'IA continue de parler avec ses balises bizarres, on affiche tout pour debugger
          {:ok, message["content"]}
        end
      {:error, _} = err -> err
    end
  end

  defp get_all_mcp_tools do
    discovery_query = %{jsonrpc: "2.0", id: 1, method: "tools/list", params: %{}} |> Jason.encode!()

    # Correction du pipe pour Linux
    cmd = "echo '#{discovery_query}' | #{mcp_docker_cmd()}"

    try do
      result = :os.cmd(String.to_charlist(cmd)) |> to_string()
      case Jason.decode(result) do
        {:ok, %{"result" => %{"tools" => tools}}} ->
          Enum.map(tools, fn t ->
            %{type: "function", function: %{name: t["name"], description: t["description"], parameters: t["inputSchema"]}}
          end)
        _ -> []
      end
    rescue
      _ -> []
    end
  end

  # Outils de secours si Docker ne répond pas à temps pour la découverte
  defp fallback_tools do
    [%{
      type: "function",
      function: %{
        name: "createTextFile",
        description: "Crée un fichier sur Drive",
        parameters: %{
          type: "object",
          properties: %{name: %{type: "string"}, content: %{type: "string"}},
          required: ["name", "content"]
        }
      }
    }]
  end

  defp handle_tool_calls(ai_message, history) do
    results = Enum.map(ai_message["tool_calls"], fn call ->
      output = execute_on_mcp_server(call["function"]["name"], call["function"]["arguments"])
      %{role: "tool", tool_call_id: call["id"], name: call["function"]["name"], content: Jason.encode!(output)}
    end)
    history ++ [ai_message] ++ results
  end

  defp mcp_docker_cmd do
    cfg = Application.get_env(:my_app, :mcp, [])
    image = cfg[:docker_image] || System.get_env("MYAPP_MCP_DOCKER_IMAGE") || "google-drive-mcp"
    host_oauth = cfg[:host_oauth_path] || System.get_env("MYAPP_MCP_OAUTH_PATH") || Path.expand("../../google-drive-mcp/gcp-oauth.keys.json", __DIR__)
    host_tokens = cfg[:host_tokens_path] || System.get_env("MYAPP_MCP_TOKENS_PATH") || Path.expand("../../google-drive-mcp/tokens.json", __DIR__)

    unless File.exists?(host_oauth) do
      IO.warn("gcp-oauth file not found at #{host_oauth}. Discovery may fail.")
    end

    "docker run -i --rm -e GOOGLE_DRIVE_OAUTH_CREDENTIALS=/config/gcp-oauth.keys.json -e GOOGLE_DRIVE_MCP_TOKEN_PATH=/config/tokens.json -v #{host_oauth}:/config/gcp-oauth.keys.json:ro -v #{host_tokens}:/config/tokens.json #{image}"
  end

  defp execute_on_mcp_server(name, args) do
    IO.puts("⚡ Appel MCP instantané : #{name}")

    # On délègue au Bridge qui gère le Docker persistant
    decoded_args = if is_binary(args), do: Jason.decode!(args), else: args

    case MyApp.MCPBridge.call_tool(name, decoded_args) do
      result -> result
    end
  end
end
