# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.2] - 2023-06-23
### Changed
- Updates for Elixir 1.15 (https://github.com/balexand/sanity_sync/pull/18).

## [0.5.1] - 2023-03-11
### Changed
- Relax `nimble_options` version requirement

## [0.5.0] - 2023-01-11
### Changed
- Reduce default batch size for `reconcile_deleted` since the old batch size would result in Sanity "414 Request-URI Too Large" errors.

## [0.4.1] - 2022-12-13
### Changed
- Relax version requirement for `:sanity` dep.

## [0.4.0] - 2022-11-14
### Added
- `Sanity.Sync.reconcile_deleted/1` (https://github.com/balexand/sanity_sync/pull/10)

### Changed
- don't call `unsafe_atomize_keys` twice in `sync/2`


## [0.3.0] - 2022-10-24
### Changed
- Use `Sanity.stream/1` under the hood for efficient pagination of large datasets, automatic retry of failed requests, and cleaner code.
- Stricter option validation using `nimble_options`.
- `sync_all` requires `types` option.
- Rename `sanity_config` option to `request_opts` for consistency with `Sanity.stream/1`.

## [0.2.1] - 2022-10-23
### Changed
- Relax version requirement for `sanity` package.
