defmodule CrucibleTrain.Distillation.PromptOnlyEnv do
  @moduledoc """
  Environment that only provides prompts with no rewards.
  """

  use CrucibleTrain.RL.ProblemEnv

  defstruct [:prompt, :renderer_module, :renderer_state, convo_prefix: nil, format_coef: 0.0]

  @type t :: %__MODULE__{
          prompt: String.t(),
          renderer_module: module(),
          renderer_state: map(),
          convo_prefix: [map()] | nil,
          format_coef: float()
        }

  @impl true
  def get_question(%__MODULE__{prompt: prompt}), do: prompt

  @impl true
  def check_format(_env, _sample_str), do: true

  @impl true
  def check_answer(_env, _sample_str), do: false

  @impl true
  def get_reference_answer(_env), do: ""
end

defmodule CrucibleTrain.Distillation.PromptOnlyDataset do
  @moduledoc """
  Dataset that yields prompt-only environments.
  """

  @behaviour CrucibleTrain.RL.RLDataset

  alias CrucibleTrain.Renderers.Helpers
  alias CrucibleTrain.RL.ProblemGroupBuilder

  defstruct [
    :prompts,
    :batch_size,
    :group_size,
    :renderer_module,
    :renderer_state,
    :tokenizer,
    :max_prompt_tokens,
    :convo_prefix,
    dataset_name: "prompts"
  ]

  @type t :: %__MODULE__{
          prompts: [String.t()],
          batch_size: pos_integer(),
          group_size: pos_integer(),
          renderer_module: module(),
          renderer_state: map(),
          tokenizer: term(),
          max_prompt_tokens: pos_integer() | nil,
          convo_prefix: [map()] | nil,
          dataset_name: String.t()
        }

  @spec new([String.t()], keyword()) :: t()
  def new(prompts, opts) do
    %__MODULE__{
      prompts: prompts,
      batch_size: Keyword.fetch!(opts, :batch_size),
      group_size: Keyword.fetch!(opts, :group_size),
      renderer_module: Keyword.fetch!(opts, :renderer_module),
      renderer_state: Keyword.fetch!(opts, :renderer_state),
      tokenizer: Keyword.fetch!(opts, :tokenizer),
      max_prompt_tokens: Keyword.get(opts, :max_prompt_tokens),
      convo_prefix: Keyword.get(opts, :convo_prefix),
      dataset_name: Keyword.get(opts, :dataset_name, "prompts")
    }
  end

  @impl true
  def get_batch(%__MODULE__{} = dataset, index) do
    batch_start = index * dataset.batch_size
    batch_end = min((index + 1) * dataset.batch_size, Kernel.length(dataset.prompts))

    if batch_start >= batch_end do
      raise ArgumentError, "Incorrect batch size"
    end

    dataset.prompts
    |> Enum.slice(batch_start, batch_end - batch_start)
    |> Enum.map(fn prompt ->
      truncated = truncate_prompt(dataset, prompt)

      %ProblemGroupBuilder{
        env_thunk: fn ->
          %CrucibleTrain.Distillation.PromptOnlyEnv{
            prompt: truncated,
            renderer_module: dataset.renderer_module,
            renderer_state: dataset.renderer_state,
            convo_prefix: dataset.convo_prefix,
            format_coef: 0.0
          }
        end,
        num_envs: dataset.group_size,
        dataset_name: dataset.dataset_name
      }
    end)
  end

  @impl true
  def length(%__MODULE__{} = dataset) do
    div(Kernel.length(dataset.prompts) + dataset.batch_size - 1, dataset.batch_size)
  end

  defp truncate_prompt(%__MODULE__{max_prompt_tokens: nil}, prompt), do: prompt

  defp truncate_prompt(%__MODULE__{max_prompt_tokens: max_tokens, tokenizer: tokenizer}, prompt) do
    tokens = Helpers.encode(tokenizer, prompt, add_special_tokens: false)

    if Kernel.length(tokens) > max_tokens do
      tokens
      |> Enum.take(max_tokens)
      |> then(&Helpers.decode(tokenizer, &1))
    else
      prompt
    end
  end
end

defmodule CrucibleTrain.Distillation.Datasets do
  @moduledoc """
  Dataset utilities for on-policy distillation.
  """

  alias CrucibleTrain.Distillation.PromptOnlyDataset

  @spec prompt_dataset([String.t()], keyword()) ::
          PromptOnlyDataset.t()
  def prompt_dataset(prompts, opts) do
    PromptOnlyDataset.new(prompts, opts)
  end
end
