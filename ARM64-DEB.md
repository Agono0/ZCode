# ARM64 `.deb` packages of the Z.ai ZCode CLI

This repository is a **fork of the official [zai-org/ZCode](https://github.com/zai-org/ZCode) source** with
additive-only changes (no upstream files are modified, so it always fast-forwards upstream):

| Path | Purpose |
| --- | --- |
| `.github/workflows/build-arm64-deb.yml` | Builds the CLI as a Debian **ARM64** `.deb` on GitHub Actions (manual `workflow_dispatch`), verifies it by installing/running it on the runner, and publishes the artifact + GitHub Release. |
| `.github/workflows/upstream-sync.yml` | Weekly fast-forward sync from upstream; automatically re-runs the `.deb` build when upstream publishes a new version. |
| `packaging/debian-arm64/build-deb.sh` | Assembles the `.deb` (installs to `/opt/zcode/bin/zcode`, symlinks `/usr/bin/zcode`). |
| `packaging/debian-arm64/README.md` | **Install / login / upgrade / uninstall instructions.** |

The package contains the official CLI **only** (terminal UI + agent; no desktop
app). The binary is the upstream-supported Node.js SEA single executable for
`linux-arm64`, so it bundles its own Node.js 24 runtime, TUI, official plugins,
bundled skills, and search tools — no system Node.js needed. The official
Z.ai **OAuth account login (`zcode login`) and Coding Plan support are
unchanged upstream code**.

**Get the latest package:** see the [releases](../../releases) or run
`.github/workflows/build-arm64-deb.yml` from the *Actions* tab.

Full usage instructions: [packaging/debian-arm64/README.md](packaging/debian-arm64/README.md).
