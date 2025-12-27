defmodule CrucibleTrain.HTTPClient do
  @moduledoc """
  Behaviour for HTTP client adapters used by logging backends.
  """

  @type method :: :get | :post | :put | :patch | :delete
  @type headers :: [{String.t(), String.t()}]

  @callback request(
              method(),
              url :: String.t(),
              body :: map() | nil,
              headers(),
              opts :: keyword()
            ) :: {:ok, map()} | {:error, term()}
end

defmodule CrucibleTrain.HTTPClient.Req do
  @moduledoc false

  @behaviour CrucibleTrain.HTTPClient

  @impl true
  def request(method, url, body, headers, opts \\ []) do
    req_opts =
      [method: method, url: url, headers: headers]
      |> maybe_put_json(body)
      |> Keyword.merge(opts)

    Req.request(req_opts)
  end

  defp maybe_put_json(req_opts, nil), do: req_opts
  defp maybe_put_json(req_opts, body), do: Keyword.put(req_opts, :json, body)
end
