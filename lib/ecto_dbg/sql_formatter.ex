defmodule EctoDbg.SQLFormatter do
  @moduledoc false

  use Rustler,
    otp_app: :ecto_dbg,
    crate: :sql_formatter

  @doc false
  def format(_sql_query), do: :erlang.nif_error(:nif_not_loaded)
end
