defmodule EctoDbgTest do
  use Ecto.Integration.Case

  alias Ecto.Integration.TestRepo

  alias EctoDbgTest.Account
  alias EctoDbgTest.User

  import Ecto.Query
  import ExUnit.CaptureLog

  describe "The TestRepo.all_and_log" do
    test "should return the correct SQL with a WHERE clause" do
      TestRepo.insert!(%Account{name: "hi"})

      query = from account in Account, where: account.name == "hi"

      expected_sql = """
      SELECT
          a0."id",
          a0."name",
          a0."email",
          a0."inserted_at",
          a0."updated_at"
      FROM
          "accounts" AS a0
      WHERE
          (a0."name" = 'hi')
      """

      assert_formatted_sql(query, :all, expected_sql)
    end

    test "should return the correct SQL with a WHERE clause when there are many IDs to match against" do
      TestRepo.insert!(%Account{name: "hi"})

      many_ids = Enum.map(1..10_000, fn _ -> Ecto.UUID.generate() end)

      query = from user in User, where: user.custom_id in ^many_ids

      expected_sql = """
      SELECT
          a0."id",
          a0."name",
          a0."email",
          a0."inserted_at",
          a0."updated_at"
      FROM
          "users" AS a0
      """

      assert_formatted_sql(query, :all, expected_sql)
    end

    test "should return the correct SQL with a JOIN clause" do
      TestRepo.insert!(%Account{name: "hi"})

      query = from account in Account, left_join: products in assoc(account, :products)

      expected_sql = """
      SELECT
          a0."id",
          a0."name",
          a0."email",
          a0."inserted_at",
          a0."updated_at"
      FROM
          "accounts" AS a0
          LEFT OUTER JOIN "products" AS p1 ON p1."account_id" = a0."id"
      """

      assert_formatted_sql(query, :all, expected_sql)
    end

    test "should return the correct SQL when a fragment is used" do
      TestRepo.insert!(%Account{name: "hi"})

      query =
        from account in Account,
          left_join: products in assoc(account, :products),
          where: fragment("? like ?", account.name, ^"%hi%"),
          or_where: fragment("? like ?", account.name, ^"%bye%")

      expected_sql = """
      SELECT
          a0."id",
          a0."name",
          a0."email",
          a0."inserted_at",
          a0."updated_at"
      FROM
          "accounts" AS a0
          LEFT OUTER JOIN "products" AS p1 ON p1."account_id" = a0."id"
      WHERE
          ((a0.\"name\" LIKE '%hi%'))
          OR (a0.\"name\" LIKE '%bye%')
      """

      assert_formatted_sql(query, :all, expected_sql)
    end
  end

  describe "The TestRepo.update_all_and_log" do
    test "should return the correct SQL when a fragment is used" do
      TestRepo.insert!(%Account{name: "hi"})

      query =
        from account in Account,
          where: fragment("? like ?", account.name, ^"%hi%"),
          update: [set: [name: "new"]]

      expected_sql = """
      UPDATE
          "accounts" AS a0
      SET
          "name" = 'new'
      WHERE
          (a0.\"name\" LIKE '%hi%')
      """

      assert_formatted_sql(query, :update_all, expected_sql)
    end
  end

  describe "The TestRepo.delete_all_and_log" do
    test "should return the correct SQL when a fragment is used" do
      TestRepo.insert!(%Account{name: "hi"})

      query =
        from account in Account,
          where: fragment("? like ?", account.name, ^"%hi%")

      expected_sql = """
      DELETE FROM
          "accounts" AS a0
      WHERE
          (a0.\"name\" LIKE '%hi%')
      """

      assert_formatted_sql(query, :delete_all, expected_sql)
    end
  end

  # ======== Helper functions ========

  defp assert_formatted_sql(query, action, opts \\ [], expected_sql) do
    raw_log =
      capture_log(fn ->
        case action do
          :all ->
            TestRepo.all_and_log(query)

          :update_all ->
            TestRepo.update_all_and_log(query, opts)

          :delete_all ->
            TestRepo.delete_all_and_log(query)
        end
      end)

    extracted_sql =
      raw_log
      |> String.split("\n")
      |> Enum.reduce({:not_sql, []}, fn
        "====" <> _, {:not_sql, acc} ->
          {:sql, acc}

        "====" <> _, {:sql, acc} ->
          ["" | acc]

        next_line, {:sql, acc} ->
          {:sql, [next_line | acc]}

        _, acc ->
          acc
      end)
      |> Enum.reverse()
      |> Enum.join("\n")

    assert extracted_sql == expected_sql
  end
end
