defmodule EctoDbg do
  @moduledoc """
  This module exposes a macro that you can inject into your Repo module so
  that you can pretty print SQL queries with the parameters espaced into the
  query. Once you `use` this module in your Repo module, you'll be able to
  call the injected functions with your query and you can see the formatted
  SQL that Ecto generates.

  > #### Warning {: .warning}
  >
  > This library makes use of [pgFormatter](https://github.com/darold/pgFormatter)
  > (which is a Perl script) in order to format your SQL queries. This is meant to
  > be a tool that is used during development and should probably not be shipped
  > with your production application. It is recommended that you add this library
  > as only a dev/test dependency.
  """

  require Logger

  @doc """
  By using this macro in your Repo module, you will get 6 additional functions added
  to your repo module. This functions are:

  * `all_and_log/1` and `all_and_log/2`
  * `update_all_and_log/1` and `update_all_and_log/2`
  * `delete_all_and_log/1` and `delete_all_and_log/2`
  * `log_all_query/1`
  * `log_update_all_query/1`
  * `log_delete_all_query/1`

  The `*_and_log` functions will output the query and will also execute it with the
  corresponding Repo function (`all`, `update_all`, and `delete_all`). The one and two
  arity versions of these functions align with the Repo functions so that these functions
  can be used as direct drop in replacements when you need to see what query is actually
  being executed by Ecto. The `log_*_query` functions will simply log out the generated
  query without executing them.

  This macro currently supports the following options that can be used to configured
  how it behaves:

  * `:level` - Specifies the log level for when the SQL query is logged (default: `:debug`).

  * `:logger_function` - Specifies the module+function that will be invoked when logging an SQL query.
    The provided module+function must have an arity of 4 and accept the following
    parameters: `repo, action, formatted_sql, opts` where opts are the options that
    were passed to the `use EctoDbg` macro. The default value is: `{EctoDbg, :default_logger}`.
  """
  defmacro __using__(opts \\ []) do
    default_opts = [
      level: :debug,
      logger_function: {EctoDbg, :default_logger}
    ]

    dbg_opts = Keyword.merge(default_opts, opts)

    quote do
      # The following functions log the query and also execute it
      def all_and_log(query, query_opts \\ []) do
        EctoDbg.run_and_log_query(__MODULE__, :all, unquote(dbg_opts), query, query_opts)
      end

      def update_all_and_log(query, query_opts \\ []) do
        EctoDbg.run_and_log_query(__MODULE__, :update_all, unquote(dbg_opts), query, query_opts)
      end

      def delete_all_and_log(query, query_opts \\ []) do
        EctoDbg.run_and_log_query(__MODULE__, :delete_all, unquote(dbg_opts), query, query_opts)
      end

      # The following functions only log the query and do not run it
      def log_all_query(query) do
        EctoDbg.log_query(__MODULE__, :all, unquote(dbg_opts), query)
      end

      def log_update_all_query(query) do
        EctoDbg.log_query(__MODULE__, :update_all, unquote(dbg_opts), query)
      end

      def log_delete_all_query(query) do
        EctoDbg.log_query(__MODULE__, :delete_all, unquote(dbg_opts), query)
      end
    end
  end

  @doc false
  def log_query(repo, action, dbg_opts, query) do
    {binary_query, params} = Ecto.Adapters.SQL.to_sql(action, repo, query)

    # Generate a formatted query
    formatted_sql =
      binary_query
      |> inline_params(params, repo.__adapter__())
      |> format_sql()
      |> format_log_message()

    # Log the query
    {logger_module, logger_function} = Keyword.fetch!(dbg_opts, :logger_function)
    apply(logger_module, logger_function, [repo, action, formatted_sql, dbg_opts])

    :ok
  end

  @doc false
  def run_and_log_query(repo, action, dbg_opts, query, query_opts \\ []) do
    # Log the Repo query
    :ok = log_query(repo, action, dbg_opts, query)

    # Run the intended Repo function
    apply(repo, action, [query, query_opts])
  end

  @doc false
  def format_log_message(formatted_sql) do
    split_query = String.split(formatted_sql, "\n")

    max_line =
      split_query
      |> Enum.max_by(fn line ->
        String.length(line)
      end)
      |> String.length()

    trimmed_query =
      split_query
      |> Enum.reduce([], fn line, acc ->
        trimmed_line = String.trim(line)

        if String.length(trimmed_line) == 0 do
          acc
        else
          [line | acc]
        end
      end)
      |> Enum.reverse()
      |> Enum.join("\n")

    """
    #{String.duplicate("=", max_line)}
    #{trimmed_query}
    #{String.duplicate("=", max_line)}
    """
  end

  @doc false
  def inline_params(query, [], _repo_adapter) do
    query
  end

  def inline_params(query, params, repo_adapter)
      when repo_adapter in [Ecto.Adapters.Postgres, Ecto.Adapters.Tds] do
    params_by_index =
      params
      |> Enum.with_index(1)
      |> Map.new(fn {value, index} -> {index, value} end)

    placeholder_with_number_regex = placeholder_with_number_regex(repo_adapter)

    query
    |> String.replace(placeholder_with_number_regex, fn
      <<_prefix::utf8, index::binary>> = replacement ->
        case Map.fetch(params_by_index, String.to_integer(index)) do
          {:ok, value} ->
            Ecto.DevLogger.PrintableParameter.to_expression(value)

          :error ->
            replacement
        end
    end)
  end

  def inline_params(query, params, Ecto.Adapters.MyXQL) do
    params_by_index =
      params
      |> Enum.with_index()
      |> Map.new(fn {value, index} -> {index, value} end)

    query
    |> String.split("?")
    |> Enum.map_reduce(0, fn elem, index ->
      formatted_value =
        case Map.fetch(params_by_index, index) do
          {:ok, value} ->
            Ecto.DevLogger.PrintableParameter.to_expression(value)

          :error ->
            []
        end

      {[elem, formatted_value], index + 1}
    end)
    |> elem(0)
  end

  @doc false
  def format_sql(raw_sql) do
    {:ok, pid, os_pid} =
      :ecto_dbg
      |> :code.priv_dir()
      |> Path.join("/pg_format")
      |> :exec.run([
        :stdin,
        :stdout,
        :stderr,
        :monitor
      ])

    :exec.send(pid, raw_sql)
    :exec.send(pid, :eof)

    # Initial state for reduce
    initial_reduce_results = %{
      stdout: "",
      stderr: []
    }

    result =
      [nil]
      |> Stream.cycle()
      |> Enum.reduce_while(initial_reduce_results, fn _, acc ->
        receive do
          {:DOWN, ^os_pid, _, ^pid, {:exit_status, exit_status}} when exit_status != 0 ->
            error = "pg_format exited with status code #{inspect(exit_status)}"
            existing_errors = Map.get(acc, :stderr, [])
            {:halt, Map.put(acc, :stderr, [error | existing_errors])}

          {:DOWN, ^os_pid, _, ^pid, _} ->
            {:halt, acc}

          {:stderr, ^os_pid, error} ->
            error = String.trim(error)
            existing_errors = Map.get(acc, :stderr, [])
            {:cont, Map.put(acc, :stderr, [error | existing_errors])}

          {:stdout, ^os_pid, compiled_template_fragment} ->
            aggregated_template = Map.get(acc, :stdout, "")
            {:cont, Map.put(acc, :stdout, aggregated_template <> compiled_template_fragment)}
        after
          10_000 ->
            :exec.kill(os_pid, :sigterm)
            error = "pg_format timed out after 10 second(s)"
            existing_errors = Map.get(acc, :stderr, [])
            {:halt, Map.put(acc, :stderr, [error | existing_errors])}
        end
      end)

    case result do
      %{stderr: [], stdout: formatted_sql} ->
        formatted_sql

      %{stderr: errors} ->
        {:error, Enum.join(errors, "\n")}
    end
  end

  defp placeholder_with_number_regex(Ecto.Adapters.Postgres), do: ~r/\$\d+/
  defp placeholder_with_number_regex(Ecto.Adapters.Tds), do: ~r/@\d+/

  @doc false
  def default_logger(repo, action, formatted_sql, opts) do
    level = Keyword.fetch!(opts, :level)

    Logger.log(
      level,
      """
      Logging raw SQL query for #{inspect(repo)}.#{Atom.to_string(action)}
      #{formatted_sql}
      """
    )
  end
end
