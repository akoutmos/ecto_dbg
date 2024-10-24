# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2024-10-23

### Changed

- Updated [sql_fmt](https://github.com/akoutmos/sql_fmt) to version `0.2.0`.

## [0.4.0] - 2024-10-06

### Changed

- Switched to precompiled Rustler NIF [sql_fmt](https://github.com/akoutmos/sql_fmt).

## [0.3.0] - 2024-09-27

### Changed

- Switched to Rustler NIF that wraps [sqlformat-rs](https://github.com/shssoichiro/sqlformat-rs) instead of Perl script
  which was choking on larger queries.

## [0.2.0] - 2023-01-28

### Added

- New `:only` option to the `use` macro to enable the debugger only in desired `Mix.env()` environments.

## [0.1.0] - 2023-01-25

### Added

- Initial release for EctoDbg to format SQL queries.
