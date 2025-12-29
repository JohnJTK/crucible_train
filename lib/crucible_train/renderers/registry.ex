defmodule CrucibleTrain.Renderers.Registry do
  @moduledoc """
  Renderer registry and lookup helpers.
  """

  alias CrucibleTrain.Renderers.Renderer

  @renderers %{
    "llama3" => CrucibleTrain.Renderers.Llama3,
    "qwen3" => CrucibleTrain.Renderers.Qwen3,
    "qwen3_vl" => CrucibleTrain.Renderers.Qwen3VL,
    "qwen3_vl_instruct" => CrucibleTrain.Renderers.Qwen3VLInstruct,
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

  # Pattern list for model name matching: {patterns_to_match, renderer_name}
  # Order matters - more specific patterns (e.g., qwen3-vl) must come before general ones (qwen3)
  @model_patterns [
    {["llama-3", "llama3"], "llama3"},
    {["qwen3-vl", "qwen3_vl", "qwen3vl"], "qwen3_vl"},
    {["qwen3"], "qwen3"},
    {["deepseek"], "deepseekv3"},
    {["kimi"], "kimi_k2"},
    {["gpt-oss", "gpt_oss"], "gpt_oss_medium_reasoning"}
  ]

  defp get_renderer_for_model(model_name) do
    downcased = String.downcase(model_name)

    case find_matching_renderer(downcased) do
      {:ok, renderer_name} -> lookup(renderer_name) |> normalize_lookup()
      :not_found -> {:error, {:unknown_renderer, model_name}}
    end
  end

  defp find_matching_renderer(downcased) do
    Enum.find_value(@model_patterns, :not_found, fn {patterns, renderer_name} ->
      if Enum.any?(patterns, &String.contains?(downcased, &1)), do: {:ok, renderer_name}
    end)
  end

  defp normalize_lookup({:ok, {module, _opts}}), do: {:ok, module}
  defp normalize_lookup({:ok, module}), do: {:ok, module}
  defp normalize_lookup({:error, _} = error), do: error
end
