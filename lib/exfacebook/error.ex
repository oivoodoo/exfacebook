defmodule Exfacebook.Error do
  @moduledoc false

  @enforce_keys [:message]
  defstruct status_code: nil, message: nil
end
