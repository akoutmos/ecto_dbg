defmodule EctoDbg do
  @moduledoc """
  This module exposes a macro that you can inject into your Repo module so
  that you can pretty print SQL queries with the parameters espaced into the
  query. Once you `use` this module in your Repo module, you'll be able to
  call the injected functions with your query and you can see the formatted
  SQL that Ecto generates.
  """

  require Logger

  alias Ecto.Adapters.SQL
  alias Ecto.DevLogger.PrintableParameter

  @doc """
  By using this macro in your Repo module, you will get 6 additional functions added
  to your repo module. This functions are:

  * `all_and_log/1` and `all_and_log/2`
  * `one_and_log/1` and `one_and_log/2`
  * `update_all_and_log/1` and `update_all_and_log/2`
  * `delete_all_and_log/1` and `delete_all_and_log/2`
  * `log_all_query/1`
  * `log_one_query/1`
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
      logger_function: {EctoDbg, :default_logger},
      only: [:test, :dev]
    ]

    dbg_opts =
      default_opts
      |> Keyword.merge(opts)
      |> Keyword.update!(:only, fn
        envs when is_list(envs) -> envs
        env when is_atom(env) -> [env]
      end)

    if Mix.env() in dbg_opts[:only] do
      quote do
        @doc """
        Run the `Repo.all` function and also log the raw SQL query.
        """
        def all_and_log(query, query_opts \\ []) do
          EctoDbg.run_and_log_query(__MODULE__, :all, unquote(dbg_opts), query, query_opts)
        end

        @doc """
        Run the `Repo.one` function and also log the raw SQL query.
        """
        def one_and_log(query, query_opts \\ []) do
          EctoDbg.run_and_log_query(__MODULE__, :one, unquote(dbg_opts), query, query_opts)
        end

        @doc """
        Run the `Repo.update_all` function and also log the raw SQL query.
        """
        def update_all_and_log(query, query_opts \\ []) do
          EctoDbg.run_and_log_query(__MODULE__, :update_all, unquote(dbg_opts), query, query_opts)
        end

        @doc """
        Run the `Repo.delete_all` function and also log the raw SQL query.
        """
        def delete_all_and_log(query, query_opts \\ []) do
          EctoDbg.run_and_log_query(__MODULE__, :delete_all, unquote(dbg_opts), query, query_opts)
        end

        @doc """
        Log the raw SQL query that would be passed to the `Repo.all` function.
        """
        # The following functions only log the query and do not run it
        def log_all_query(query) do
          EctoDbg.log_query(__MODULE__, :all, unquote(dbg_opts), query)
        end

        @doc """
        Log the raw SQL query that would be passed to the `Repo.one` function.
        """
        # The following functions only log the query and do not run it
        def log_one_query(query) do
          EctoDbg.log_query(__MODULE__, :one, unquote(dbg_opts), query)
        end

        @doc """
        Log the raw SQL query that would be passed to the `Repo.update_all` function.
        """
        def log_update_all_query(query) do
          EctoDbg.log_query(__MODULE__, :update_all, unquote(dbg_opts), query)
        end

        @doc """
        Log the raw SQL query that would be passed to the `Repo.delete_all` function.
        """
        def log_delete_all_query(query) do
          EctoDbg.log_query(__MODULE__, :delete_all, unquote(dbg_opts), query)
        end
      end
    end
  end

  @doc false
  def log_query(repo, action, dbg_opts, query) do
    normalized_action = if action == :one, do: :all, else: action
    {binary_query, params} = SQL.to_sql(normalized_action, repo, query)

    # Generate a formatted query
    formatted_log_message =
      binary_query
      |> inline_params(params, repo.__adapter__())
      |> SqlFmt.format_query(indent: 4)
      |> case do
        {:ok, formatted_sql} ->
          format_log_message(formatted_sql)
      end

    # Log the query
    {logger_module, logger_function} = Keyword.fetch!(dbg_opts, :logger_function)
    apply(logger_module, logger_function, [repo, action, formatted_log_message, dbg_opts])

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
            PrintableParameter.to_expression(value)

          :error ->
            replacement
        end
    end)
  end

  def inline_params(query, params, Ecto.Adapters.SQLite3) do
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
            PrintableParameter.to_expression(value)

          :error ->
            []
        end

      {[elem, formatted_value], index + 1}
    end)
    |> elem(0)
    |> List.flatten()
    |> Enum.join()
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
            PrintableParameter.to_expression(value)

          :error ->
            []
        end

      {[elem, formatted_value], index + 1}
    end)
    |> elem(0)
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
