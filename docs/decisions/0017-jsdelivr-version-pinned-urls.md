# ADR-0017: jsDelivr CDN with version-pinned URLs for SRD content

**Status:** Accepted
**Date:** 2026-03-21

## Context

SRD JSON content (and community packs) needs a reliable hosting URL that GMs can
register as a source. The obvious starting point is GitHub, but raw GitHub URLs
have significant limitations in production use.

## Decision

Use **jsDelivr** as the CDN layer over GitHub content:

```
https://cdn.jsdelivr.net/gh/{owner}/{repo}@{tag}/{path}
```

Example:
```
https://cdn.jsdelivr.net/gh/seansbox/daggerheart-srd@v1.2.0/adversaries.json
```

Always use **version-pinned URLs** (a git tag or commit hash). Never use `@main`
or `@latest`.

### Why version-pinned

jsDelivr permanently caches all served files in S3 storage. Cache purges exist
but are documented as frequently unreliable. Version-pinned URLs make this
behavior a feature: each version's URL is stable and cached forever. When SRD
content updates, a new tag is published and the URL changes. GMs explicitly
choose when to update a source — their cached content never changes unexpectedly.

### Why jsDelivr over raw.githubusercontent.com

- `raw.githubusercontent.com` ignores authentication headers entirely. Rate
  limits are IP-based and opaque (~5,000 req/hr unauthenticated, but GitHub
  discourages production use of raw URLs.
- jsDelivr provides global CDN distribution (Cloudflare + Fastly), better
  uptime, and documented (if imperfect) cache management.

### Privacy note

All requests through jsDelivr are visible to jsDelivr, Cloudflare, and Fastly
(IP address and user agent logged; no cookies). For community game content this
is acceptable. The app should note in its settings that source refreshes make
network requests.

## Options Considered

- **raw.githubusercontent.com (rejected):** GitHub discourages production use.
  Auth headers ignored. Rate limits opaque. No CDN.
- **GitHub REST API (rejected):** Proper auth and rate-limit headers, but returns
  base64-encoded content, requires parsing, and is rate-limited at 60 req/hr
  unauthenticated (5,000 with token). Unnecessary complexity for infrequent pulls.
- **GitHub Pages / Cloudflare Pages (alternative):** More control over caching
  and invalidation. Valid if a source author wants full control. The app should
  accept any valid HTTPS URL, not require jsDelivr specifically.
- **jsDelivr (chosen as recommended default):** Reliable, no auth required,
  global CDN, version-pinned URLs make permanent caching a feature.

## Consequences

- Source URLs registered in the app should prefer tagged/commit-hash URLs.
- The UI should warn if a user registers an `@latest` or `@main` URL.
- The app accepts any valid HTTPS JSON URL — jsDelivr is the recommended
  pattern for GitHub-hosted content, not a hard requirement.
- See ADR-0018 for the user-initiated fetch strategy.
