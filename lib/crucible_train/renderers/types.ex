defmodule CrucibleTrain.Renderers.Types do
  @moduledoc """
  Type definitions for the renderer system.
  """

  defmodule TextPart do
    @moduledoc """
    A text content part in a multimodal message.
    """
    @enforce_keys [:type, :text]
    defstruct [:type, :text]

    @type t :: %__MODULE__{
            type: String.t(),
            text: String.t()
          }
  end

  defmodule ImagePart do
    @moduledoc """
    An image content part in a multimodal message.
    """
    @enforce_keys [:type, :image]
    defstruct [:type, :image]

    @type t :: %__MODULE__{
            type: String.t(),
            image: String.t() | binary()
          }
  end

  @type content_part :: TextPart.t() | ImagePart.t()
  @type content :: String.t() | [content_part()]

  defmodule FunctionBody do
    @moduledoc """
    The function body of a tool call containing name and arguments.
    """
    @enforce_keys [:name, :arguments]
    defstruct [:name, :arguments]

    @type t :: %__MODULE__{
            name: String.t(),
            arguments: String.t()
          }
  end

  defmodule ToolCall do
    @moduledoc """
    A tool/function call following the OpenAI format.
    """
    @enforce_keys [:type, :function]
    defstruct [:type, :function, :id]

    @type t :: %__MODULE__{
            type: String.t(),
            function: FunctionBody.t(),
            id: String.t() | nil
          }
  end

  defmodule ToolOk do
    @moduledoc """
    Successful tool execution result.
    """
    defstruct output: "", message: "", brief: ""

    @type t :: %__MODULE__{
            output: String.t(),
            message: String.t(),
            brief: String.t()
          }
  end

  defmodule ToolError do
    @moduledoc """
    Tool execution error result.
    """
    defstruct output: "", message: "", brief: ""

    @type t :: %__MODULE__{
            output: String.t(),
            message: String.t(),
            brief: String.t()
          }
  end

  defmodule ToolResult do
    @moduledoc """
    Complete tool execution result with tracking ID.
    """
    defstruct [:tool_call_id, :result]

    @type t :: %__MODULE__{
            tool_call_id: String.t() | nil,
            result: ToolOk.t() | ToolError.t()
          }
  end

  defmodule Message do
    @moduledoc """
    A single message in a conversation.
    """
    @enforce_keys [:role, :content]
    defstruct [:role, :content, :tool_calls, :thinking, :trainable, :tool_call_id, :name]

    @type t :: %__MODULE__{
            role: String.t(),
            content: CrucibleTrain.Renderers.Types.content(),
            tool_calls: [CrucibleTrain.Renderers.Types.ToolCall.t()] | nil,
            thinking: String.t() | nil,
            trainable: boolean() | nil,
            tool_call_id: String.t() | nil,
            name: String.t() | nil
          }
  end

  defmodule RenderedMessage do
    @moduledoc """
    A rendered message containing token chunks for training/sampling.
    """
    @enforce_keys [:content]
    defstruct [:prefix, :content, :suffix]

    @type chunk :: map()

    @type t :: %__MODULE__{
            prefix: chunk() | nil,
            content: [chunk()],
            suffix: chunk() | nil
          }
  end

  @doc """
  Creates a text content part.
  """
  @spec text_part(String.t()) :: TextPart.t()
  def text_part(text) when is_binary(text) do
    %TextPart{type: "text", text: text}
  end

  @doc """
  Creates an image content part.
  """
  @spec image_part(String.t() | binary()) :: ImagePart.t()
  def image_part(image) do
    %ImagePart{type: "image", image: image}
  end

  @doc """
  Creates a conversation message.
  """
  @spec message(String.t(), content(), keyword()) :: Message.t()
  def message(role, content, opts \\ []) when is_binary(role) do
    %Message{
      role: role,
      content: content,
      tool_calls: Keyword.get(opts, :tool_calls),
      thinking: Keyword.get(opts, :thinking),
      trainable: Keyword.get(opts, :trainable),
      tool_call_id: Keyword.get(opts, :tool_call_id),
      name: Keyword.get(opts, :name)
    }
  end

  @doc """
  Creates a tool call.
  """
  @spec tool_call(String.t(), String.t(), keyword()) :: ToolCall.t()
  def tool_call(name, arguments, opts \\ []) when is_binary(name) and is_binary(arguments) do
    %ToolCall{
      type: "function",
      function: %FunctionBody{name: name, arguments: arguments},
      id: Keyword.get(opts, :id)
    }
  end

  @doc """
  Ensures content is text-only and returns it as a string.
  """
  @spec ensure_text(content()) :: String.t()
  def ensure_text(content) when is_binary(content), do: content
  def ensure_text([%TextPart{text: text}]), do: text
  def ensure_text([%{"type" => "text", "text" => text}]) when is_binary(text), do: text
  def ensure_text([%{type: "text", text: text}]) when is_binary(text), do: text

  def ensure_text(content) when is_list(content) do
    raise ArgumentError,
          "Expected text content, got multimodal content with #{length(content)} parts"
  end

  @doc """
  Normalizes content into a list of content parts.
  """
  @spec ensure_parts(content()) :: [content_part()]
  def ensure_parts(content) when is_binary(content) do
    [%TextPart{type: "text", text: content}]
  end

  def ensure_parts(parts) when is_list(parts) do
    Enum.map(parts, fn
      %TextPart{} = part ->
        part

      %ImagePart{} = part ->
        part

      %{"type" => "text", "text" => text} when is_binary(text) ->
        %TextPart{type: "text", text: text}

      %{type: "text", text: text} when is_binary(text) ->
        %TextPart{type: "text", text: text}

      %{"type" => "image", "image" => image} ->
        %ImagePart{type: "image", image: image}

      %{type: "image", image: image} ->
        %ImagePart{type: "image", image: image}

      other ->
        raise ArgumentError, "Invalid content part: #{inspect(other)}"
    end)
  end
end
