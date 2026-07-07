# Solr 8 / 9 / 10 Compatibility Update Plan

## Overview

Make `solr_cloud-connection` work correctly with Solr 8, 9, and 10 simultaneously. The approach:
branch on `major_version` where APIs differ, and use V1 (legacy) APIs where they work uniformly
across versions.

Version detection is already in place in `connection.rb` via `major_version`, `minor_version`,
and `patch_version` methods derived from `GET /solr/admin/info/system`.

Source examined: `main` branch and `fix/solr-10-api-compatibility` branch.
API docs source: Apache Solr Reference Guide 10.0 (live, fetched May 2026).

---

## Root Cause

The main branch uses Solr 8-era V2 API paths for configset management
(`api/cluster/configs/*`). These paths changed in Solr 9/10 to `api/configsets/*`.
Additionally, the V1 `LISTALIASES` action returns `null` (not `{}`) in Solr 10 when
no aliases exist, causing a `NoMethodError` on `nil.keys`.

The `fix/solr-10-api-compatibility` branch already addresses this by switching configset
operations wholesale to V1 APIs and adding a `|| {}` nil guard, but it does so without
version branching. This plan implements proper version-based dispatch.

---

## API Compatibility Matrix

| Method / File | Solr 8 (main branch) | Solr 9/10 compat? | Notes |
|---|---|---|---|
| `configset_admin#create_configset` | `PUT api/cluster/configs/{name}` (V2) | NO | V2 path changed |
| `configset_admin#configset_names` | `GET api/cluster/configs` (V2) | NO | V2 path changed |
| `configset_admin#delete_configset` | `DELETE api/cluster/configs/{name}` (V2) | NO | V2 path changed |
| `alias_admin#raw_alias_map` | `GET solr/admin/collections?action=LISTALIASES` | PARTIAL | returns nil when empty |
| `alias_admin#create_alias` | V1 CREATEALIAS | YES | V1 works in all versions |
| `alias#delete!` | V1 DELETEALIAS | YES | V1 works in all versions |
| `collection_admin#only_collections` | `GET api/collections` (V2) | YES | same response format |
| `collection_admin#create_collection` | V1 CREATE | YES | V1 works in all versions |
| `collection#delete!` | V1 DELETE | YES | V1 works in all versions |
| `collection#info` | `GET api/collections/{name}` (V2) | UNKNOWN | needs testing; see below |

---

## Changes Required

### 1. `connection.rb` -- add version-helper predicate

Add a convenience predicate to avoid repeating `major_version >= 9` comparisons inline:

```ruby
# Returns true for Solr 9 and later (including 10, 11, ...)
def solr9_or_later?
  major_version >= 9
end
```

Place it alongside the existing `major_version` / `minor_version` / `patch_version` methods.
No changes to `bail_if_incompatible!`.

---

### 2. `connection/configset_admin.rb` -- version-branch all three methods

The V2 configset paths changed between Solr 8 and Solr 9:

| Operation | Solr 8 V2 path | Solr 9/10 V2 path | V1 path (all versions) |
|---|---|---|---|
| Upload | `PUT api/cluster/configs/{name}` | `PUT api/configsets/{name}` | `POST solr/admin/configs?action=UPLOAD&name={name}` |
| List | `GET api/cluster/configs` -> `["configSets"]` | `GET api/configsets` -> `["configSets"]` | `GET solr/admin/configs?action=LIST` -> `["configSets"]` |
| Delete | `DELETE api/cluster/configs/{name}` | `DELETE api/configsets/{name}` | `GET solr/admin/configs?action=DELETE&name={name}` |

Strategy: use V1 for Solr 9+, keep existing V2 for Solr 8. V1 works in Solr 8 too, so
an alternative is to use V1 for all versions and avoid branching entirely -- but the task
requires explicit version dispatch.

#### `create_configset`

```ruby
def create_configset(name:, confdir:, force: false)
  raise WontOverwriteError.new("Configset '#{name}' already exists") if has_configset?(name) && !force
  zipfile = zip_configset_dir(confdir)
  if connection.solr9_or_later?
    connection.post("solr/admin/configs?action=UPLOAD&name=#{name}") do |req|
      req.headers["Content-Type"] = "application/octet-stream"
      req.body = File.binread(zipfile)
    end
  else
    connection.put("api/cluster/configs/#{name}") do |req|
      req.headers["Content-Type"] = "application/octet-stream"
      req.body = File.binread(zipfile)
    end
  end
  get_configset(name)
ensure
  FileUtils.rm_f(zipfile) if zipfile
end
```

Note: the `fix` branch uses `connection.post("solr/admin/configs", action: "UPLOAD",
name: name)` but that places action/name as query params on a POST. The Solr V1 API
docs specify these as query string parameters for the UPLOAD action, so either form works.
Verify with integration tests.

#### `configset_names`

```ruby
def configset_names
  if connection.solr9_or_later?
    connection.get("solr/admin/configs", action: "LIST").body["configSets"]
  else
    connection.get("api/cluster/configs").body["configSets"]
  end
end
```

#### `delete_configset`

```ruby
def delete_configset(name:)
  return unless has_configset?(name)
  if connection.solr9_or_later?
    connection.get("solr/admin/configs", action: "DELETE", name: name)
  else
    connection.delete("api/cluster/configs/#{name}")
  end
end
```

---

### 3. `connection/alias_admin.rb` -- nil guard (bug fix, not version-specific)

`raw_alias_map` crashes with `NoMethodError` when no aliases exist because the Solr
`LISTALIASES` response omits the `aliases` key entirely (returns `null` or simply absent).
This is confirmed on Solr 10 and the fix is straightforward:

```ruby
def raw_alias_map
  connection.get("solr/admin/collections", action: "LISTALIASES").body["aliases"] || {}
end
```

This fix is already present in `fix/solr-10-api-compatibility`. It is not version-specific --
apply it unconditionally, as it is defensive coding.

---

### 4. `lib/solr_cloud/collection.rb` -- verify `info` endpoint (needs testing)

`Collection#info` calls:

```ruby
connection.get("api/collections/#{name}").body["cluster"]["collections"][name]
```

The response path `body["cluster"]["collections"][name]` matches the structure returned by
the V1 `CLUSTERSTATUS` API and the V2 `GET /api/cluster` endpoint. Whether
`GET /api/collections/{name}` returns this same nested structure in Solr 9/10 is not
confirmed from docs alone.

**Action required:**
- Run integration tests against Solr 9 and Solr 10 containers with the existing code
- If `api/collections/{name}` returns a different response structure in Solr 9/10,
  add version branching:

  ```ruby
  def info
    if connection.solr9_or_later?
      # Fallback to V1 CLUSTERSTATUS filtered to this collection
      connection.get("solr/admin/collections",
        action: "CLUSTERSTATUS",
        collection: name
      ).body["cluster"]["collections"][name]
    else
      connection.get("api/collections/#{name}").body["cluster"]["collections"][name]
    end
  end
  ```

  V1 `CLUSTERSTATUS` with `collection` param is confirmed to work in both Solr 8 and 10
  and returns the exact same `cluster.collections.{name}` structure.

---

### 5. No changes needed

The following use V1 APIs or V2 APIs that are stable across Solr 8, 9, and 10:

- `alias_admin#create_alias` -- V1 `CREATEALIAS`
- `alias#delete!` -- V1 `DELETEALIAS`
- `collection_admin#create_collection` -- V1 `CREATE`
- `collection_admin#only_collections` -- `GET api/collections` response format confirmed
  unchanged in Solr 10 (`{"collections": [...]}`)
- `collection#delete!` -- V1 `DELETE`
- `connection#system` / `version_string` / `major_version` etc. -- `/solr/admin/info/system`
  unchanged

---

## Implementation Pattern

Use private dispatch methods to keep the public interface clean:

```ruby
# In ConfigsetAdmin module:

def create_configset(name:, confdir:, force: false)
  raise WontOverwriteError.new(...) if has_configset?(name) && !force
  zipfile = zip_configset_dir(confdir)
  solr9_or_later? ? upload_configset_v1(name, zipfile) : upload_configset_v8(name, zipfile)
  get_configset(name)
ensure
  FileUtils.rm_f(zipfile) if zipfile
end

private

def upload_configset_v1(name, zipfile)
  connection.post("solr/admin/configs?action=UPLOAD&name=#{name}") do |req|
    req.headers["Content-Type"] = "application/octet-stream"
    req.body = File.binread(zipfile)
  end
end

def upload_configset_v8(name, zipfile)
  connection.put("api/cluster/configs/#{name}") do |req|
    req.headers["Content-Type"] = "application/octet-stream"
    req.body = File.binread(zipfile)
  end
end
```

Where the dispatch is simple (one line each branch), inline `if/else` is acceptable.
Prefer private methods when the per-version logic is more than 2 lines.

---

## Test Infrastructure

The existing spec infrastructure uses Docker Compose in `spec/data/solr_docker/`.

Add a Solr 10 service (and optionally Solr 9) alongside the existing Solr 8 service:

```yaml
# In spec/data/solr_docker/docker-compose.yml (new service):
solr10:
  image: solr:10-slim
  ports:
    - "18984:8983"
  command: solr-demo
  # or whatever start command the existing solr8 service uses
```

Update the integration test runner (likely a Rake task or script) to run the full spec
suite twice: once against Solr 8 and once against Solr 10 (passing the base URL as an
environment variable).

If the test suite already accepts a `SOLR_URL` environment variable, this is straightforward.
If it hardcodes a port, parameterize it.

---

## Implementation Order

1. Add `solr9_or_later?` to `connection.rb`
2. Apply `|| {}` nil guard to `alias_admin.rb#raw_alias_map` (already in fix branch --
   cherry-pick or re-apply)
3. Version-branch `configset_admin.rb`: `configset_names`, `delete_configset`,
   `create_configset` (in that order -- names and delete first so tests can verify the
   cycle without broken upload)
4. Add Solr 10 container to Docker Compose test setup
5. Run integration tests against both Solr 8 and Solr 10
6. If `Collection#info` fails against Solr 10, add version-branch (step 4 above)
7. Update gem version (patch or minor, depending on whether the nil-guard fix is considered
   a breaking change)

---

## Notes on the fix/solr-10-api-compatibility Branch

That branch's approach (switch all configset ops to V1 unconditionally) is functionally
correct and simpler. If backward compatibility with the V2 Solr 8 behavior is not a concern,
that approach is acceptable and lower-risk than version branching. The user has explicitly
requested version-based dispatch, which this plan implements.

If Solr 8 V2 API support is dropped in a future major version of the gem, the branches
can be collapsed to use V1 everywhere.
