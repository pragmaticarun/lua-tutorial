# Learn Lua: From Foundations to Embedding

A hands-on Lua course for systems developers (C++, Rust, Android, multimedia),
built with MkDocs Material. Every code sample is a real file that CI runs on
**Lua 5.5.1**, **Lua 5.4.9** and **LuaJIT 2.1**, and the output shown in the docs
is the expected output the tests compare against.

## Status

- Part 1 (Foundations, lessons 1–9): written and tested.
- Parts 2–4 and Projects: outlined, coming soon.

## Quick start

```bash
sudo apt install build-essential curl git python3-venv
scripts/install-interpreters.sh          # builds lua5.5, lua5.4, luajit under /opt
tests/run_all.sh                         # runs every example on every interpreter
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/mkdocs serve                   # http://127.0.0.1:8000
```

## Repository layout

| Path | What |
|---|---|
| `docs/` | Markdown pages |
| `examples/NN-slug/` | Lua snippets, `.expected` outputs, stdin inputs |
| `includes/badges/` | Per-lesson "Tested with" badges (generated) |
| `tests/run_all.sh` | Test runner (pass/fail per interpreter) |
| `scripts/install-interpreters.sh` | Builds the three interpreters (used by CI) |
| `.github/workflows/site.yml` | Test, build (`--strict`) and deploy to GitHub Pages |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the authoring conventions.

## Deploying

The workflow deploys with `actions/deploy-pages`. In the GitHub repository
settings, set **Pages → Build and deployment → Source** to **GitHub Actions**.
