<p align="center">
  <img align="center" width="25%" src="guides/images/logo.png" alt="EctoDbg Elixir Logo">
  <img align="center" width="35%" src="guides/images/logo_name.png" alt="EctoDbg title">
</p>

<p align="center">
  Easily debug and pretty print your Ecto SQL queries
</p>

<p align="center">
  <a href="https://hex.pm/packages/ecto_dbg">
    <img alt="Hex.pm" src="https://img.shields.io/hexpm/v/ecto_dbg?style=for-the-badge">
  </a>

  <a href="https://github.com/akoutmos/ecto_dbg/actions">
    <img alt="GitHub Workflow Status (master)"
    src="https://img.shields.io/github/actions/workflow/status/akoutmos/ecto_dbg/main.yml?label=Build%20Status&style=for-the-badge&branch=master">
  </a>

  <a href="https://coveralls.io/github/akoutmos/ecto_dbg?branch=master">
    <img alt="Coveralls master branch" src="https://img.shields.io/coveralls/github/akoutmos/ecto_dbg/master?style=for-the-badge">
  </a>

  <a href="https://github.com/sponsors/akoutmos">
    <img alt="Support the project" src="https://img.shields.io/badge/Support%20the%20project-%E2%9D%A4-lightblue?style=for-the-badge">
  </a>
</p>

<br>

# Contents

- [Installation](#installation)
- [Supporting EctoDbg](#supporting-ectodbg)
- [Setting Up EctoDbg](#setting-up-ectodbg)
- [Attribution](#attribution)

## Installation

[Available in Hex](https://hex.pm/packages/ecto_dbg), the package can be installed by adding `ecto_dbg` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_dbg, "~> 0.1.0", only: [:dev, :test]}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/ecto_dbg](https://hexdocs.pm/ecto_dbg).

## Supporting EctoDbg

If you rely on this library help you debug your Ecto queries, it would much appreciated if you can give back
to the project in order to help ensure its continued development.

Checkout my [GitHub Sponsorship page](https://github.com/sponsors/akoutmos) if you want to help out!

### Gold Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58083">
  <img align="center" height="175" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Silver Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58082">
  <img align="center" height="150" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Bronze Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=17615">
  <img align="center" height="125" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

## Setting Up EctoDbg

After adding `{:ecto_dbg, "~> 0.1.0"}` in your `mix.exs` file and running `mix deps.get`, open your `repo.ex` file and
add the following contents:

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  use EctoDbg
end
```

You can also pass configuration options to `EctoDbg` if you so chose like so (see the `EctoDbg` module docs
for more information):

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  use EctoDbg, level: :info
end
```

With that in place, any time that you want to inspect a query that is executed by Ecto, all you need to do
is the following

```elixir
query = from user in User

Repo.all_and_log(query)
```

By default the `use EctoDbg` macro will inject the debug functions into your repo module for only the `:test` and `:dev`
`Mix.env()` environments. If you would like to override this default behaviour, you can do that by providing the `:only`
option (this value should be a subset of the environments that you passed in your `mix.exs` file):

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  use EctoDbg, only: :dev
end
```

## Attribution

- EctoDbg builds upon the [EctoDevLogger](https://github.com/fuelen/ecto_dev_logger) package and has reused some of the
  code in that project to achieve a slightly different goal.
- The logo for the project is an edited version of an SVG image from the [unDraw project](https://undraw.co/).
- The EctoDbg library wraps [pgFormatter](https://github.com/darold/pgFormatter) in order to provide SQL formatting.
