defmodule SharedSettings.Setting do
  @enforce_keys [:name, :type, :value]
  defstruct [:name, :type, :value]

  @type t :: %SharedSettings.Setting{name: String.t(), type: String.t(), value: String.t()}
end
