defmodule CrucibleTrain.Logging.NeptuneLogger do
  @moduledoc """
  Neptune.ai logger backend using HTTP API.

  Uses the official Neptune API with OAuth2 token exchange for authentication.
  The API token is a base64-encoded JSON containing the API address.

  ## Configuration

  - `:api_token` - Neptune API token (base64-encoded JSON with api_address)
  - `:project` - Project qualified name (workspace/project)

  ## Example

      {:ok, logger} = NeptuneLogger.init(
        api_token: System.get_env("NEPTUNE_API_TOKEN"),
        project: "workspace/project-name"
      )
  """

  @behaviour CrucibleTrain.Logging.Logger

  require Logger

  alias CrucibleTrain.HTTPClient
  alias CrucibleTrain.Logging.DumpConfig

  defstruct [
    :api_token,
    :access_token,
    :project,
    :project_id,
    :run_id,
    :sys_id,
    :workspace,
    :base_url,
    :http_client,
    :request_opts,
    :rate_limit
  ]

  @type rate_limit_opts :: %{
          min_interval_ms: non_neg_integer(),
          max_retries: non_neg_integer(),
          base_backoff_ms: non_neg_integer(),
          max_backoff_ms: non_neg_integer()
        }

  @type t :: %__MODULE__{
          api_token: String.t(),
          access_token: String.t() | nil,
          project: String.t(),
          project_id: String.t() | nil,
          run_id: String.t() | nil,
          sys_id: String.t() | nil,
          workspace: String.t() | nil,
          base_url: String.t(),
          http_client: module(),
          request_opts: keyword(),
          rate_limit: rate_limit_opts() | nil
        }

  @default_base_url "https://app.neptune.ai"

  @default_rate_limit %{
    min_interval_ms: 200,
    max_retries: 3,
    base_backoff_ms: 1_000,
    max_backoff_ms: 30_000
  }

  @impl true
  def init(opts) do
    api_token = Keyword.get(opts, :api_token) || System.get_env("NEPTUNE_API_TOKEN")
    project = Keyword.get(opts, :project)
    http_client = Keyword.get(opts, :http_client, HTTPClient.Req)
    request_opts = Keyword.get(opts, :request_opts, [])
    rate_limit = parse_rate_limit_opts(Keyword.get(opts, :rate_limit, true))

    with {:ok, api_token} <- validate_api_token(api_token),
         {:ok, project} <- validate_project(project),
         {:ok, base_url} <- parse_api_token(api_token, opts),
         {:ok, access_token} <-
           exchange_api_token(http_client, base_url, api_token, request_opts),
         {:ok, project_info} <-
           get_project(http_client, base_url, access_token, project, request_opts),
         {:ok, run_info} <-
           create_run(http_client, base_url, access_token, project_info, request_opts) do
      {:ok,
       %__MODULE__{
         api_token: api_token,
         access_token: access_token,
         project: project,
         project_id: project_info.id,
         run_id: run_info.id,
         sys_id: run_info.sys_id,
         workspace: run_info.workspace,
         base_url: base_url,
         http_client: http_client,
         request_opts: request_opts,
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
    # Convert metrics to Neptune operations
    timestamp_ms = System.system_time(:millisecond)

    operations =
      metrics
      |> DumpConfig.dump()
      |> flatten_metrics("metrics")
      |> Enum.map(fn {path, value} ->
        %{
          "path" => path,
          "logFloats" => %{
            "entries" => [
              %{
                "value" => to_float(value),
                "step" => (step || 0) * 1.0,
                "timestampMilliseconds" => timestamp_ms
              }
            ]
          }
        }
      end)

    execute_operations(state, operations)
    |> handle_request_result("log_metrics")
  end

  @impl true
  def log_hparams(%__MODULE__{run_id: nil}, _hparams), do: :ok

  def log_hparams(%__MODULE__{} = state, hparams) do
    # Convert hparams to Neptune assign operations
    operations =
      hparams
      |> DumpConfig.dump()
      |> flatten_metrics("parameters")
      |> Enum.map(fn {path, value} ->
        build_assign_operation(path, value)
      end)

    execute_operations(state, operations)
    |> handle_request_result("log_hparams")
  end

  @impl true
  def close(%__MODULE__{run_id: nil}), do: :ok

  def close(%__MODULE__{} = state) do
    # Neptune doesn't require explicit close - runs auto-complete
    # But we can set the state to "Idle" to signal completion
    operations = [
      %{
        "path" => "sys/state",
        "assignString" => %{"value" => "Idle"}
      }
    ]

    execute_operations(state, operations)
    |> handle_request_result("close")
  end

  @impl true
  def sync(_state), do: :ok

  @impl true
  def get_url(%__MODULE__{run_id: nil}), do: nil

  def get_url(%__MODULE__{} = state) do
    "#{state.base_url}/#{state.project}/e/#{state.sys_id}"
  end

  @impl true
  def log_long_text(%__MODULE__{run_id: nil}, _key, _text), do: :ok

  def log_long_text(%__MODULE__{} = state, key, text) do
    operations = [
      %{
        "path" => to_string(key),
        "assignString" => %{"value" => text}
      }
    ]

    execute_operations(state, operations)
    |> handle_request_result("log_long_text")
  end

  # Private functions

  defp validate_api_token(nil), do: {:error, :missing_api_token}
  defp validate_api_token(""), do: {:error, :missing_api_token}
  defp validate_api_token(value), do: {:ok, value}

  defp validate_project(nil), do: {:error, :missing_project}
  defp validate_project(""), do: {:error, :missing_project}
  defp validate_project(value), do: {:ok, value}

  defp parse_api_token(api_token, opts) do
    # Check if base_url is explicitly provided (for testing)
    case Keyword.get(opts, :base_url) do
      nil -> parse_api_token_from_value(api_token)
      base_url -> {:ok, base_url}
    end
  end

  defp parse_api_token_from_value(api_token) do
    case Base.decode64(api_token) do
      {:ok, json} -> extract_base_url_from_json(json)
      :error -> {:ok, @default_base_url}
    end
  end

  defp extract_base_url_from_json(json) do
    case Jason.decode(json) do
      {:ok, %{"api_address" => api_address}} -> {:ok, api_address}
      {:ok, %{"api_url" => api_url}} -> {:ok, api_url}
      {:ok, _} -> {:ok, @default_base_url}
      {:error, _} -> {:error, :invalid_api_token}
    end
  end

  defp exchange_api_token(http_client, base_url, api_token, request_opts) do
    url = base_url <> "/api/backend/v1/authorization/api-token/exchange"
    headers = [{"X-Neptune-Api-Token", api_token}, {"Content-Type", "application/json"}]

    case http_request(http_client, :post, url, %{}, headers, request_opts) do
      {:ok, %{"accessToken" => access_token}} ->
        {:ok, access_token}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_project(http_client, base_url, access_token, project, request_opts) do
    url = base_url <> "/api/backend/v1/projects/#{URI.encode(project, &URI.char_unreserved?/1)}"
    headers = auth_headers(access_token)

    case http_request(http_client, :get, url, nil, headers, request_opts) do
      {:ok, %{"id" => id, "name" => name, "organizationName" => org}} ->
        {:ok, %{id: id, name: name, workspace: org}}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_run(http_client, base_url, access_token, project_info, request_opts) do
    url = base_url <> "/api/leaderboard/v1/experiments"
    headers = auth_headers(access_token)

    body = %{
      "projectIdentifier" => project_info.id,
      "parentId" => project_info.id,
      "type" => "run",
      "cliVersion" => "crucible_train/0.2.0"
    }

    case http_request(http_client, :post, url, body, headers, request_opts) do
      {:ok, %{"id" => id, "shortId" => sys_id, "organizationName" => workspace}} ->
        {:ok, %{id: id, sys_id: sys_id, workspace: workspace}}

      {:ok, %{"id" => id} = response} ->
        # Handle minimal response
        {:ok, %{id: id, sys_id: response["shortId"] || id, workspace: project_info.workspace}}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp execute_operations(%__MODULE__{}, []), do: {:ok, []}

  defp execute_operations(%__MODULE__{} = state, operations) do
    url = state.base_url <> "/api/leaderboard/v1/experiments/#{state.run_id}/operations"
    headers = auth_headers(state.access_token)
    body = %{"operations" => operations}

    rate_limited_request(state, fn ->
      http_request(state.http_client, :post, url, body, headers, state.request_opts)
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
        Logger.debug("Neptune rate limited, retrying in #{backoff_ms}ms (attempt #{attempt + 1})")
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

  defp auth_headers(access_token) do
    [{"Authorization", "Bearer #{access_token}"}, {"Content-Type", "application/json"}]
  end

  defp flatten_metrics(map, prefix) when is_map(map) do
    Enum.flat_map(map, fn {key, value} ->
      path = "#{prefix}/#{key}"

      if is_map(value) and not is_struct(value) do
        flatten_metrics(value, path)
      else
        [{path, value}]
      end
    end)
  end

  defp flatten_metrics(value, prefix), do: [{prefix, value}]

  defp build_assign_operation(path, value) when is_binary(value) do
    %{"path" => path, "assignString" => %{"value" => value}}
  end

  defp build_assign_operation(path, value) when is_float(value) do
    %{"path" => path, "assignFloat" => %{"value" => value}}
  end

  defp build_assign_operation(path, value) when is_integer(value) do
    %{"path" => path, "assignInt" => %{"value" => value}}
  end

  defp build_assign_operation(path, value) when is_boolean(value) do
    %{"path" => path, "assignBool" => %{"value" => value}}
  end

  defp build_assign_operation(path, value) do
    # Fallback to string for other types
    %{"path" => path, "assignString" => %{"value" => inspect(value)}}
  end

  defp to_float(value) when is_float(value), do: value
  defp to_float(value) when is_integer(value), do: value * 1.0
  defp to_float(_value), do: 0.0

  defp emit_telemetry(duration, method, url, status, ok, error \\ nil) do
    metadata = %{method: method, url: url, status: status, ok: ok, error: error}

    :telemetry.execute(
      [:crucible_train, :logging, :neptune, :request],
      %{duration: duration},
      metadata
    )
  end

  defp handle_request_result({:ok, _response}, _action), do: :ok

  defp handle_request_result({:error, reason}, action) do
    Logger.warning("Neptune #{action} failed: #{inspect(reason)}")
    :ok
  end
end
