---
name: run-netroot-io
description: Build, serve, and screenshot netroot.io — a static HTML landing page normally deployed via Docker/nginx to Railway. Use when asked to run netroot-io, start it locally, take a screenshot of it, or verify its nginx redirect rules (/humility, /la-mystique-divine → breviarium.ink).
---

netroot-io is a static site (`index.html` + `styles.css`) served in
production by the `Dockerfile` (nginx:alpine + `nginx.conf`). There's
no Docker in this environment, so it's driven by running the real
`nginx.conf` directly against Homebrew nginx (`serve.sh`), then
screenshotting it with a Playwright driver (`driver.mjs` — chromium-cli
isn't installed here, so this hand-rolled script is the harness of
record).

All paths below are relative to `netroot-io/` (this repo's root).

## Prerequisites

```bash
brew install nginx   # only if `command -v nginx` is empty
```

```bash
cd .claude/skills/run-netroot-io && npm install   # installs playwright, once
```

## Run (agent path)

1. Serve the real nginx config against this checkout:

```bash
.claude/skills/run-netroot-io/serve.sh 8899
```

This substitutes `$PORT` in `nginx.conf` the same way the Dockerfile's
`CMD` does, rewrites the docroot from the container path
(`/usr/share/nginx/html`) to this checkout, and launches nginx with a
throwaway config in `/tmp/netroot-io-nginx-test/`. It prints the exact
stop command.

2. Screenshot it and check for console errors:

```bash
cd .claude/skills/run-netroot-io
node driver.mjs http://127.0.0.1:8899/ /tmp/netroot-screenshot.png
```

Prints the page `<title>`, the screenshot path, and any browser
console errors (non-empty `CONSOLE_ERRORS` or a crash means something's
wrong — go look at the screenshot).

3. Verify the redirect rules (these are nginx-specific `return 301`s
   that a plain static file server won't exercise):

```bash
curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}\n" http://127.0.0.1:8899/humility
curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}\n" http://127.0.0.1:8899/la-mystique-divine
# both → "301 -> https://breviarium.ink/<path>/"
```

4. Stop nginx when done (`serve.sh` prints this exact line each run):

```bash
nginx -c /tmp/netroot-io-nginx-test/nginx.conf -p /tmp/netroot-io-nginx-test/ -s stop
```

## Run (human path)

Open `index.html` directly in a browser, or `python3 -m http.server`
from the repo root — fine for eyeballing the page, but it won't
exercise the nginx redirect rules above.

## Test

No test suite — this is a static HTML/CSS site with no build step.
The screenshot + redirect checks above are the verification.

---

## Gotchas

- **`driver.mjs` must use `import`, not `require`.** The `.mjs`
  extension forces ES module scope; `require('playwright')` throws
  `ReferenceError: require is not defined in ES module scope`.
- **`nginx.conf`'s `root` is a container path.** It's hardcoded to
  `/usr/share/nginx/html` (where the Dockerfile `COPY`s the files).
  `serve.sh` rewrites this to the actual repo path with `sed` — if you
  hand-roll a config instead, don't forget this substitution or nginx
  will 404 on everything.
- **`$PORT` is a literal string in `nginx.conf` and the Dockerfile's
  `CMD`**, substituted at container start via `sed`. `serve.sh` does
  the same substitution locally.
- **No Docker in this environment.** The Homebrew-nginx route in
  `serve.sh` is what's actually verified here; if Docker is available
  elsewhere, `docker build . -t netroot-io && docker run -e PORT=8899
  -p 8899:8899 netroot-io` is the more faithful (unverified-here)
  alternative.
