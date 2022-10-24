# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Use `Sanity.stream/1` under the hood for efficient pagination of large datasets, automatic retry of failed requests, and cleaner code.
- Stricter option validation using `nimble_options`.
- `sync_all` requires `types` option.
- Rename `sanity_config` option to `request_opts` for consistency with `Sanity.stream/1`.

## [0.2.1] - 2022-10-23

### Changed

- Relax version requirement for `sanity` package.
