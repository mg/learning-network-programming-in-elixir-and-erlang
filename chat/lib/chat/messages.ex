defmodule Chat.Message do
  defmodule Register do
    @type t() :: %__MODULE__{username: String.t()}
    defstruct [:username]
  end

  defmodule Broadcast do
    @type t() :: %__MODULE__{from_username: String.t(), contents: String.t()}
    defstruct [:from_username, :contents]
  end
end
