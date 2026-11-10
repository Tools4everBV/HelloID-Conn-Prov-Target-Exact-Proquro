# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [1.0.0] - 2026-11-04

This is the first official release of _HelloID-Conn-Prov-Target-Exact-Proquro_. This release is based on the current _HelloID-Conn-Prov-Target-V2-Template_ (no template version published).

### Added

- Field mapping and `configuration.json`.

### Changed

- Converted the create script from PowerShell V1 to V2.
- The token request is now a form-urlencoded POST and uses the `access_token` of the response.

### Deprecated

### Removed

- The `IsConnectionTls12` setting: TLS 1.2 is always enabled.
- The empty `password` field.
