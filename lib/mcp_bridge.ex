defmodule MyApp.MCPBridge do
  use GenServer
  require Logger

  # --- Client API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def call_tool(name, args) do
    Logger.info("🛠️  Envoi de la requête au serveur MCP: #{name}")
    GenServer.call(__MODULE__, {:call_tool, name, args}, 30_000)
  end

  # --- Server Callbacks ---

  def init(:ok) do
    Logger.info("🔌 Initialisation du Bridge MCP...")

    docker_cmd = build_docker_cmd()
    Logger.debug("Docker command for MCP: #{docker_cmd}")

    # Lancement du port
    port = Port.open({:spawn, docker_cmd}, [:binary, :exit_status])

    # On obtient l'OS PID pour le debug
    {:os_pid, pid} = Port.info(port, :os_pid)
    Logger.info("🚀 Serveur MCP lancé avec succès (Docker PID: #{pid})")

    {:ok, %{port: port, last_caller: nil, buffer: ""}}
  end

  def handle_call({:call_tool, name, args}, from, state) do
    mcp_request = %{
      jsonrpc: "2.0",
      id: :rand.uniform(1000),
      method: "tools/call",
      params: %{name: name, arguments: args}
    } |> Jason.encode!()

    Port.command(state.port, mcp_request <> "\n")

    {:noreply, %{state | last_caller: from}}
  end

  # Capture des messages sortants du serveur MCP
  def handle_info({_port, {:data, binary}}, state) do
    Logger.debug("📥 Données reçues du MCP: #{binary}")

    case filter_mcp_json(binary) do
      nil ->
        # C'est peut-être un message de log du serveur MCP
        Logger.info("📡 Log Serveur MCP: #{String.trim(binary)}")
        {:noreply, state}

      decoded ->
        if state.last_caller do
          Logger.info("✅ Réponse JSON valide reçue, transfert à l'IA.")
          GenServer.reply(state.last_caller, decoded)
        end
        {:noreply, %{state | last_caller: nil}}
    end
  end

  # Gestion de l'arrêt du container
  def handle_info({_port, {:exit_status, status}}, state) do
    Logger.error("⚠️ Le serveur MCP (Docker) s'est arrêté avec le code: #{status}")
    {:stop, :port_closed, state}
  end

  # --- Helpers ---

  defp build_docker_cmd do
    cfg = Application.get_env(:my_app, :mcp, [])
    image = cfg[:docker_image] || System.get_env("MYAPP_MCP_DOCKER_IMAGE") || "google-drive-mcp"
    host_oauth = cfg[:host_oauth_path] || System.get_env("MYAPP_MCP_OAUTH_PATH") || Path.expand("../../google-drive-mcp/gcp-oauth.keys.json", __DIR__)
    host_tokens = cfg[:host_tokens_path] || System.get_env("MYAPP_MCP_TOKENS_PATH") || Path.expand("../../google-drive-mcp/tokens.json", __DIR__)

    unless File.exists?(host_oauth) do
      Logger.warn("gcp-oauth file not found at #{host_oauth}. Docker may fail to start.")
    end

    unless File.exists?(host_tokens) do
      Logger.warn("tokens file not found at #{host_tokens}. Docker may fail to start.")
    end

    "docker run -i --rm -e GOOGLE_DRIVE_OAUTH_CREDENTIALS=/config/gcp-oauth.keys.json -e GOOGLE_DRIVE_MCP_TOKEN_PATH=/config/tokens.json -v #{host_oauth}:/config/gcp-oauth.keys.json:ro -v #{host_tokens}:/config/tokens.json #{image}"
  end

  defp filter_mcp_json(binary) do
    binary
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      trimmed = String.trim(line)
      if String.starts_with?(trimmed, "{") do
        case Jason.decode(trimmed) do
          {:ok, json} -> json
          _ -> nil
        end
      end
    end)
  end
end
