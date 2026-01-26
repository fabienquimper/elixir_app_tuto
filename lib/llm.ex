defmodule MyApp.ChatGPT do
  @doc """
  Sends a prompt to the local LM Studio instance and returns the model's response.
  """
  def ask_question(prompt) do
    # Local LM Studio endpoint
    url = "http://192.168.1.66:1234/v1/chat/completions"

    # Headers: Local servers usually don't require an API key (Bearer token).
    headers = [
      {"Content-Type", "application/json"}
    ]

    # Request body: Using the model name you specified.
    body = %{
      model: "openai/gpt-oss-20b",
      messages: [%{role: "user", content: prompt}],
      temperature: 0.7
    }

    # Increased receive_timeout (60s) because local inference speed depends on your hardware.
    case Req.post(url, json: body, headers: headers, receive_timeout: 60_000) do
      {:ok, %{status: 200, body: response}} ->
        # Extracting the message content from the OpenAI-compatible JSON structure
        content =
          response["choices"]
          |> List.first()
          |> get_in(["message", "content"])

        {:ok, content}

      {:ok, %{status: status, body: error_body}} ->
        # Handle server-side errors (e.g., model not loaded or wrong parameters)
        {:error, "LM Studio returned status #{status}: #{inspect(error_body)}"}

      {:error, exception} ->
        # Handle network issues (e.g., wrong IP, port closed, or server offline)
        {:error, "Connection failed: #{inspect(exception)}"}
    end
  end
end
