# Changelog

## [1.0.0] - 2026-07-07

### Major — Solr 8/9/10 Dual-Version Compatibility

This release adds support for Solr 9 and 10 alongside the existing Solr 8 support.
The internal API dispatch now detects the connected Solr major version and routes
requests to the correct endpoint, since several Solr APIs changed paths or response
envelopes between Solr 8 and Solr 9/10.

- **Feature: Solr 8/9/10 compatibility**
  - Use V1 `CLUSTERSTATUS` action for collection info instead of V2 `api/collections/{name}`
    (the V2 response envelope changed between Solr 8 and Solr 9/10 — the `cluster` wrapper
    key is absent in Solr 10)
  - Use V1 `LISTALIASES` action with `|| {}` guard for nil aliases on Solr 10
  - Use V1 `admin/configs` endpoint for configset upload (path differs between Solr 8 and 9+)
  - Add `solr9_or_later?` predicate to the connection for external version-gating
- **CI: Matrix testing** — run tests against Solr 8 & Solr 10 in parallel via GitHub Actions
- **Infrastructure** — Docker Compose healthchecks, env setup for Solr 10 test container, curl-based wait loops

### Chores
- Replace `wait-for-it` / raw curl loops with Docker Compose healthcheck + `docker compose wait`
- Add Solr 10 Docker image definition (`spec/data/solr10_docker/`)
- Update README
- Version bump to 1.0.0

## [0.6.0] - 2025-05-29
- Expose `username` and `password` getters on the connection
- Update README with "Common Usage" section
- Peg dependency versions in gemspec
- General gemfile/spec cleanup

## [0.5.0] - 2025-03-24
- Added some sugar for unifying aliases and collections
- Update tests
- Better errors
- Flesh out README.md to be a useful document


## [0.4.0] - 2023-12-07
- Fixed rules about what names are legal collections/configsets/aliases
- Update version and changelog

## [0.3.0] - 2023-12-06

- Major overhaul of the interface to use more-explicit and less-confusing method names
- Remove code that tried to "version" collections and configsets, since it was dumb
- Get github actions working to run tests
- Make aliases even more of a paper-thin wrapper around collections, such that, e.g.
  `coll = get_collection(alias_name)` will return the appropriate alias. Use
  `coll.alias?` to determine if it's an alias or collection if that becomes important.

## [0.2.0] - 2023-12-01

- Added options `:date` and `:datetime` to the `version:` argument to `create_collection`
  to automatically generate, e.g., "2023-12-01" or "2023-12-01-09-50-56" 
- Added utility method `legal_solr_name?` to check for validity for collection names

## [0.1.0] - 2023-11-29

- Initial release
