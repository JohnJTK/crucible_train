defmodule CrucibleTrain.Renderers.Registry do
  @moduledoc """
  Renderer registry and lookup helpers.
  """

  alias CrucibleTrain.Renderers.Renderer

  @renderers %{
    "llama3" => CrucibleTrain.Renderers.Llama3,
    "qwen3" => CrucibleTrain.Renderers.Qwen3,
    "qwen3_disable_thinking" => CrucibleTrain.Renderers.Qwen3DisableThinking,
    "qwen3_instruct" => CrucibleTrain.Renderers.Qwen3Instruct,
    "deepseekv3" => CrucibleTrain.Renderers.DeepSeekV3,
    "deepseekv3_disable_thinking" => CrucibleTrain.Renderers.DeepSeekV3DisableThinking,
    "kimi_k2" => CrucibleTrain.Renderers.KimiK2,
    "gpt_oss_no_sysprompt" => {CrucibleTrain.Renderers.GptOss, [use_system_prompt: false]},
    "gpt_oss_low_reasoning" =>
      {CrucibleTrain.Renderers.GptOss, [use_system_prompt: true, reasoning_effort: "low"]},
    "gpt_oss_medium_reasoning" =>
      {CrucibleTrain.Renderers.GptOss, [use_system_prompt: true, reasoning_effort: "medium"]},
    "gpt_oss_high_reasoning" =>
      {CrucibleTrain.Renderers.GptOss, [use_system_prompt: true, reasoning_effort: "high"]},
    "role_colon" => CrucibleTrain.Renderers.RoleColon
  }

  @spec get(String.t(), map(), keyword()) :: {:ok, Renderer.state()} | {:error, term()}
  def get(name, tokenizer, opts \\ []) do
    case lookup(name) do
      {:ok, {module, extra_opts}} ->
        module.init([{:tokenizer, tokenizer} | extra_opts] ++ opts)

      {:ok, module} ->
        module.init([{:tokenizer, tokenizer} | opts])

      {:error, _} = error ->
        error
    end
  end

  @spec get_renderer(String.t()) :: {:ok, module()} | {:error, term()}
  def get_renderer(name) do
    case lookup(name) do
      {:ok, {module, _extra_opts}} -> {:ok, module}
      {:ok, module} -> {:ok, module}
      {:error, _} -> get_renderer_for_model(name)
    end
  end

  @spec lookup(String.t()) :: {:ok, module()} | {:ok, {module(), keyword()}} | {:error, term()}
  def lookup(name) do
    case Map.fetch(@renderers, name) do
      {:ok, {module, extra_opts}} -> {:ok, {module, extra_opts}}
      {:ok, module} -> {:ok, module}
      :error -> {:error, {:unknown_renderer, name}}
    end
  end

  @spec list_renderers() :: [String.t()]
  def list_renderers, do: Map.keys(@renderers)

  defp get_renderer_for_model(model_name) do
    downcased = String.downcase(model_name)

    cond do
      String.contains?(downcased, "llama-3") or String.contains?(downcased, "llama3") ->
        lookup("llama3") |> normalize_lookup()

      String.contains?(downcased, "qwen3") ->
        lookup("qwen3") |> normalize_lookup()

      String.contains?(downcased, "deepseek") ->
        lookup("deepseekv3") |> normalize_lookup()

      String.contains?(downcased, "kimi") ->
        lookup("kimi_k2") |> normalize_lookup()

      String.contains?(downcased, "gpt-oss") or String.contains?(downcased, "gpt_oss") ->
        lookup("gpt_oss_medium_reasoning") |> normalize_lookup()

      true ->
        {:error, {:unknown_renderer, model_name}}
    end
  end

  defp normalize_lookup({:ok, {module, _opts}}), do: {:ok, module}
  defp normalize_lookup({:ok, module}), do: {:ok, module}
  defp normalize_lookup({:error, _} = error), do: error
end
