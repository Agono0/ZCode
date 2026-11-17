# ZCode CLI — Debian ARM64 (`.deb`)

Prebuilt **Z.ai ZCode CLI** for **Linux ARM64 (aarch64)**, packaged as a Debian
`.deb`. This is the **CLI only** (terminal UI + agent runtime) — the desktop
application is not included.

Built entirely on GitHub Actions from the **unmodified official upstream source**
([zai-org/ZCode](https://github.com/zai-org/ZCode)). Nothing in the upstream
tree is patched, so the fork stays a fast-forward of upstream and the official
authentication stack ships untouched:

- `zcode login` / `/login` — the official Z.ai OAuth device flow
- Coding Plan support (Project Access Token exchange, key management)
- Credentials in `~/.zcode/v2/credentials.json`, encrypted with the upstream
  `@napi-rs/keyring` pipeline (with upstream's headless fallbacks:
  `ZCODE_CREDENTIAL_SECRET` / `ZCODE_CREDENTIAL_SECRET_FILE`)

The shipped binary is the upstream-supported **Node.js SEA single executable**
(`apps/zcode-cli/packages/cli/scripts/build-sea.mjs --target linux-arm64`): the
Node.js 24 runtime, TUI, agent, official plugins, bundled skills, and the
native search tools (ripgrep/ugrep/bfs) are all embedded. **No system Node.js
is required** (Debian's `nodejs` package is older than the Node 24 runtime
ZCode needs anyway).

## Requirements

- Debian 12 (bookworm) or newer, **arm64** — `libc6 >= 2.28` and
  `libstdc++6 >= 12` are declared as dependencies, so older releases refuse to
  install rather than fail at runtime.
- Works inside Termux too: install a Debian ARM64 distribution first
  (`pkg install proot-distro && proot-distro install debian`), then run all
  commands below inside `proot-distro login debian`.
- Recommended: `git` (declared as a `Recommends` entry; ZCode uses it heavily).

## Install

Download the `.deb` from the
[latest release](../../releases) (or the run's
[artifacts](../../actions/workflows/build-arm64-deb.yml)), then:

```bash
# from the directory containing the downloaded file
sudo apt install ./zcode-cli_<VERSION>-<REV>_arm64.deb
# or, equivalently
sudo dpkg -i zcode-cli_<VERSION>-<REV>_arm64.deb
```

`apt install ./file.deb` also pulls the declared dependencies for you.

Verify:

```bash
zcode --version
command -v zcode   # -> /usr/bin/zcode
```

## Log in

```bash
zcode
# or explicitly:
zcode login
```

Follow the OAuth device-flow prompt (it prints a URL and a code; open it on
any device, sign in with your Z.ai account, and approve). After login, the
Coding Plan (Project Access Token) flow works exactly as in the official CLI —
no API-key configuration is needed.

## Upgrade

New releases are attached to the
[releases page](../../releases) as
`zcode-cli_<VERSION>-<REV>_arm64.deb`. Install the newer file over the old one;
configuration and login state in `~/.zcode/` are preserved:

```bash
sudo apt install ./zcode-cli_<NEW-VERSION>-<REV>_arm64.deb
# or
sudo dpkg -i zcode-cli_<NEW-VERSION>-<REV>_arm64.deb
```

The package is not served from an apt repository, so plain `apt upgrade` will
not update it — download the newer `.deb` when a new release appears
(the `Sync upstream and rebuild` workflow refreshes the release automatically
when upstream publishes a new version).

## Uninstall

```bash
sudo apt remove zcode-cli
# or
sudo dpkg -r zcode-cli
```

This removes `/opt/zcode` and the `/usr/bin/zcode` symlink. Your user data
(logins, sessions, settings under `~/.zcode/`) is intentionally **not**
deleted; remove it manually if you want a full wipe:

```bash
rm -rf ~/.zcode
```

## Installed files

| Path                                    | Purpose                                  |
| --------------------------------------- | ---------------------------------------- |
| `/opt/zcode/bin/zcode`                  | The CLI single executable (Node SEA)     |
| `/usr/bin/zcode`                        | Symlink to the executable                |
| `/usr/share/doc/zcode-cli/`             | License, third-party notices, this README |

## How this is built

- Build workflow: [.github/workflows/build-arm64-deb.yml](../../blob/main/.github/workflows/build-arm64-deb.yml)
  — manual `workflow_dispatch` trigger, runs on GitHub's native ARM64 runner
  (`ubuntu-24.04-arm`).
- Pipeline: install pinned toolchain (Node 24.14.0 + pnpm 10.33.2 from upstream
  `mise.toml`) → `pnpm run build:sea:prepare` → upstream SEA build for
  `linux-arm64` → assemble the `.deb` (`packaging/debian-arm64/build-deb.sh`)
  → **install and run the `.deb` on the runner to verify it** → upload the
  artifact and publish the GitHub Release.
- Upstream tracking: [.github/workflows/upstream-sync.yml](../../blob/main/.github/workflows/upstream-sync.yml)
  — fast-forwards `main` to `zai-org/ZCode` weekly and re-runs the `.deb`
  build. No upstream files are modified in this fork, so the merge is always a
  fast-forward.
- Re-running the build for the same upstream version replaces the existing
  release of that version (tag `zcode-cli-v<VERSION>`).
