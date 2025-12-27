defmodule CrucibleTrain.Logging.WandbLogger do
  @moduledoc """
  Weights & Biases logger backend using HTTP API.

  Uses the official W&B GraphQL API for run management and file stream API
  for logging metrics and history.

  ## Configuration

  Requires the following options on init:
  - `:api_key` - W&B API key (or set WANDB_API_KEY env var)
  - `:project` - Project name
  - `:entity` - Optional team/user name (defaults to user's default entity)

  ## Example

      {:ok, logger} = WandbLogger.init(
        api_key: System.get_env("WANDB_API_KEY"),
        project: "my-project",
        entity: "my-team",
        run_name: "experiment-1"
      )
  """

  @behaviour CrucibleTrain.Logging.Logger

  require Logger

  alias CrucibleTrain.HTTPClient
  alias CrucibleTrain.Logging.DumpConfig

  defstruct [
    :api_key,
    :project,
    :entity,
    :run_id,
    :run_name,
    :display_name,
    :base_url,
    :http_client,
    :request_opts,
    :history_step,
    :rate_limit
  ]

  @type rate_limit_opts :: %{
          min_interval_ms: non_neg_integer(),
          max_retries: non_neg_integer(),
          base_backoff_ms: non_neg_integer(),
          max_backoff_ms: non_neg_integer()
        }

  @type t :: %__MODULE__{
          api_key: String.t(),
          project: String.t(),
          entity: String.t() | nil,
          run_id: String.t() | nil,
          run_name: String.t() | nil,
          display_name: String.t() | nil,
          base_url: String.t(),
          http_client: module(),
          request_opts: keyword(),
          history_step: non_neg_integer(),
          rate_limit: rate_limit_opts() | nil
        }

  @default_rate_limit %{
    min_interval_ms: 500,
    max_retries: 3,
    base_backoff_ms: 1_000,
    max_backoff_ms: 30_000
  }

  @base_url "https://api.wandb.ai"
  @ui_base_url "https://wandb.ai"

  # GraphQL mutation for creating/updating runs
  @upsert_bucket_mutation """
  mutation UpsertBucket(
    $id: String,
    $name: String,
    $project: String,
    $entity: String,
    $groupName: String,
    $description: String,
    $displayName: String,
    $notes: String,
    $commit: String,
    $config: JSONString,
    $host: String,
    $debug: Boolean,
    $program: String,
    $repo: String,
    $jobType: String,
    $state: String,
    $sweep: String,
    $tags: [String!],
    $summaryMetrics: JSONString
  ) {
    upsertBucket(input: {
      id: $id,
      name: $name,
      groupName: $groupName,
      modelName: $project,
      entityName: $entity,
      description: $description,
      displayName: $displayName,
      notes: $notes,
      config: $config,
      commit: $commit,
      host: $host,
      debug: $debug,
      jobProgram: $program,
      jobRepo: $repo,
      jobType: $jobType,
      state: $state,
      sweep: $sweep,
      tags: $tags,
      summaryMetrics: $summaryMetrics
    }) {
      bucket {
        id
        name
        displayName
        description
        config
        project {
          id
          name
          entity {
            id
            name
          }
        }
      }
      inserted
    }
  }
  """

  @impl true
  def init(opts) do
    api_key = Keyword.get(opts, :api_key) || System.get_env("WANDB_API_KEY")
    project = Keyword.get(opts, :project)
    entity = Keyword.get(opts, :entity)
    run_name = Keyword.get(opts, :run_name)
    display_name = Keyword.get(opts, :display_name, run_name)
    base_url = Keyword.get(opts, :base_url, @base_url)
    http_client = Keyword.get(opts, :http_client, HTTPClient.Req)
    request_opts = Keyword.get(opts, :request_opts, [])
    rate_limit = parse_rate_limit_opts(Keyword.get(opts, :rate_limit, true))

    with {:ok, api_key} <- validate_api_key(api_key),
         {:ok, project} <- validate_project(project),
         {:ok, run_info} <-
           create_run(
             http_client,
             base_url,
             api_key,
             project,
             entity,
             run_name,
             display_name,
             request_opts
           ) do
      {:ok,
       %__MODULE__{
         api_key: api_key,
         project: run_info.project,
         entity: run_info.entity,
         run_id: run_info.run_id,
         run_name: run_info.run_name,
         display_name: run_info.display_name,
         base_url: base_url,
         http_client: http_client,
         request_opts: request_opts,
         history_step: 0,
         rate_limit: rate_limit
       }}
    end
  end

  defp parse_rate_limit_opts(false), do: nil
  defp parse_rate_limit_opts(nil), do: nil
  defp parse_rate_limit_opts(true), do: @default_rate_limit

  defp parse_rate_limit_opts(opts) when is_list(opts) do
    Map.merge(@default_rate_limit, Map.new(opts))
  end

  defp parse_rate_limit_opts(opts) when is_map(opts) do
    Map.merge(@default_rate_limit, opts)
  end

  @impl true
  def log_metrics(%__MODULE__{run_id: nil}, _step, _metrics), do: :ok

  def log_metrics(%__MODULE__{} = state, step, metrics) do
    # Build history entry with step and runtime
    history_entry =
      metrics
      |> DumpConfig.dump()
      |> Map.put("_step", step || state.history_step)
      |> Map.put("_runtime", System.system_time(:second))

    # Send via file stream API
    payload = %{
      "files" => %{
        "wandb-history.jsonl" => %{
          "offset" => state.history_step,
          "content" => [Jason.encode!(history_entry)]
        }
      },
      "dropped" => 0
    }

    state
    |> file_stream_request(payload)
    |> handle_request_result("log_metrics")
  end

  @impl true
  def log_hparams(%__MODULE__{run_id: nil}, _hparams), do: :ok

  def log_hparams(%__MODULE__{} = state, hparams) do
    config_json = hparams |> DumpConfig.dump() |> Jason.encode!()

    variables = %{
      "id" => state.run_id,
      "entity" => state.entity,
      "project" => state.project,
      "config" => config_json
    }

    state
    |> graphql_request(@upsert_bucket_mutation, variables)
    |> handle_request_result("log_hparams")
  end

  @impl true
  def close(%__MODULE__{run_id: nil}), do: :ok

  def close(%__MODULE__{} = state) do
    # Send complete signal via file stream
    payload = %{
      "complete" => true,
      "exitcode" => 0,
      "dropped" => 0,
      "uploaded" => []
    }

    state
    |> file_stream_request(payload)
    |> handle_request_result("close")
  end

  @impl true
  def sync(_state), do: :ok

  @impl true
  def get_url(%__MODULE__{run_id: nil}), do: nil

  def get_url(%__MODULE__{} = state) do
    "#{@ui_base_url}/#{state.entity}/#{state.project}/runs/#{state.run_name}"
  end

  @impl true
  def log_long_text(%__MODULE__{run_id: nil}, _key, _text), do: :ok

  def log_long_text(%__MODULE__{} = state, key, text) do
    # Log as summary metric
    summary = %{to_string(key) => text}
    summary_json = Jason.encode!(summary)

    variables = %{
      "id" => state.run_id,
      "entity" => state.entity,
      "project" => state.project,
      "summaryMetrics" => summary_json
    }

    state
    |> graphql_request(@upsert_bucket_mutation, variables)
    |> handle_request_result("log_long_text")
  end

  # Private functions

  defp validate_api_key(nil), do: {:error, :missing_api_key}
  defp validate_api_key(""), do: {:error, :missing_api_key}
  defp validate_api_key(value), do: {:ok, value}

  defp validate_project(nil), do: {:error, :missing_project}
  defp validate_project(""), do: {:error, :missing_project}
  defp validate_project(value), do: {:ok, value}

  defp create_run(
         http_client,
         base_url,
         api_key,
         project,
         entity,
         run_name,
         display_name,
         request_opts
       ) do
    variables =
      %{
        "project" => project,
        "displayName" => display_name
      }
      |> maybe_put("entity", entity)
      |> maybe_put("name", run_name)

    headers = auth_headers(api_key)
    url = base_url <> "/graphql"

    body = %{
      "query" => @upsert_bucket_mutation,
      "variables" => variables
    }

    case http_request(http_client, :post, url, body, headers, request_opts) do
      {:ok, response_body} ->
        extract_run_info(response_body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp graphql_request(%__MODULE__{} = state, query, variables) do
    headers = auth_headers(state.api_key)
    url = state.base_url <> "/graphql"

    body = %{
      "query" => query,
      "variables" => variables
    }

    http_request(state.http_client, :post, url, body, headers, state.request_opts)
  end

  defp file_stream_request(%__MODULE__{} = state, payload) do
    headers = auth_headers(state.api_key)
    url = "#{state.base_url}/files/#{state.entity}/#{state.project}/#{state.run_name}/file_stream"

    rate_limited_request(state, fn ->
      http_request(state.http_client, :post, url, payload, headers, state.request_opts)
    end)
  end

  defp rate_limited_request(%__MODULE__{rate_limit: nil}, request_fn) do
    request_fn.()
  end

  defp rate_limited_request(%__MODULE__{rate_limit: rate_limit}, request_fn) do
    # Enforce minimum interval between requests
    Process.sleep(rate_limit.min_interval_ms)

    # Execute with retry on rate limit
    do_rate_limited_request(request_fn, rate_limit, 0)
  end

  defp do_rate_limited_request(request_fn, rate_limit, attempt) do
    case request_fn.() do
      {:error, {:http_error, 429, _body}} when attempt < rate_limit.max_retries ->
        backoff_ms = calculate_backoff(rate_limit, attempt)
        Logger.debug("W&B rate limited, retrying in #{backoff_ms}ms (attempt #{attempt + 1})")
        Process.sleep(backoff_ms)
        do_rate_limited_request(request_fn, rate_limit, attempt + 1)

      result ->
        result
    end
  end

  defp calculate_backoff(rate_limit, attempt) do
    backoff = rate_limit.base_backoff_ms * :math.pow(2, attempt)
    min(round(backoff), rate_limit.max_backoff_ms)
  end

  defp http_request(http_client, method, url, body, headers, request_opts) do
    start = System.monotonic_time()
    result = http_client.request(method, url, body, headers, request_opts)
    duration = System.monotonic_time() - start

    case result do
      {:ok, response} ->
        {status, response_body} = normalize_response(response)
        ok = status in 200..299

        emit_telemetry(duration, method, url, status, ok)

        if ok do
          {:ok, response_body}
        else
          {:error, {:http_error, status, response_body}}
        end

      {:error, reason} ->
        emit_telemetry(duration, method, url, nil, false, reason)
        {:error, reason}
    end
  end

  defp normalize_response(response) do
    {fetch_status(response), decode_body(fetch_body(response))}
  end

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      _ -> body
    end
  end

  defp decode_body(body), do: body

  defp fetch_status(%{status: status}), do: status
  defp fetch_status(%{"status" => status}), do: status
  defp fetch_status(_), do: nil

  defp fetch_body(%{body: body}), do: body
  defp fetch_body(%{"body" => body}), do: body
  defp fetch_body(other), do: other

  defp extract_run_info(%{"data" => %{"upsertBucket" => %{"bucket" => bucket}}}) do
    run_id = bucket["id"]
    run_name = bucket["name"]
    display_name = bucket["displayName"]

    project_info = bucket["project"] || %{}
    project_name = project_info["name"]

    entity_info = project_info["entity"] || %{}
    entity_name = entity_info["name"]

    {:ok,
     %{
       run_id: run_id,
       run_name: run_name,
       display_name: display_name,
       project: project_name,
       entity: entity_name
     }}
  end

  defp extract_run_info(%{"errors" => [%{"message" => message} | _]}) do
    {:error, {:graphql_error, message}}
  end

  defp extract_run_info(%{"errors" => errors}) when is_list(errors) do
    {:error, {:graphql_error, inspect(errors)}}
  end

  defp extract_run_info(other) do
    {:error, {:unexpected_response, other}}
  end

  defp auth_headers(api_key) do
    # W&B uses HTTP Basic Auth with username "api" and the API key as password
    credentials = Base.encode64("api:#{api_key}")
    [{"Authorization", "Basic #{credentials}"}, {"Content-Type", "application/json"}]
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp emit_telemetry(duration, method, url, status, ok, error \\ nil) do
    metadata = %{method: method, url: url, status: status, ok: ok, error: error}

    :telemetry.execute(
      [:crucible_train, :logging, :wandb, :request],
      %{duration: duration},
      metadata
    )
  end

  defp handle_request_result({:ok, _response}, _action), do: :ok

  defp handle_request_result({:error, reason}, action) do
    Logger.warning("W&B #{action} failed: #{inspect(reason)}")
    :ok
  end
end
