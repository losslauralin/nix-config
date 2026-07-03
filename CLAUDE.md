# NixOS Configuration Agent Guide

NixOS / `denful/den` aspect-oriented architecture + `flake-parts`. Terminology & mental model in `CONTEXT.md`.
Local namespace: `lossilk` (registered in `modules/den.nix`).

## Commands (must use just wrappers)

**Never call nix/nh/nixos-rebuild directly. Always use justfile wrappers.**
The `justfile` is generated from the `modules/flake-parts` machinery; the recipes below mirror the actual installable surface.

```
# Validation
just              # alias for `just check` (default)
just check        # nix flake check (nom-by-default, NO_NOM=1 / non-tty falls back)
just fmt          # treefmt — formatters only (alejandra, shfmt, rustfmt, black, ...)
just lint         # treefmt --fail-on-change — static lint only (deadnix, statix, shellcheck, ruff-check)
just fmt-check    # treefmt --fail-on-change across all programs (format + lint)
just check-all    # fmt-check + check

# Build / deploy
just os-switch    # nh os switch            (e.g. just os-switch .#nixos-wsl --ask)
just os-build     # nh os build
just build        # generic nix build wrapped with nom
just nb           # generic nix build --no-link wrapped with nom (exploratory builds)
just update       # nix flake update
just store-clean  # nh clean [subcommand]   (default: all)

# VM / disk image
just build-vm     # nix build .#<host>.config.system.build.vm -o /tmp/result-<host>
just test-vm      # build-vm <host> + run-vm <host>
just run-vm       # boot /tmp/result-<host>/bin/run-<host>-vm
just list-image-variants <host>          # available --image-variant values
just build-image  <host> <variant>       # nixos-rebuild build-image --image-variant

# Change-impact
just diff         <host>                 # nvd diff: /run/current-system vs new build
just diff-revs    <host> <ref>           # nvd diff: git <ref> vs working tree
just why          <host> <attr>          # nix why-depends on a host's system
just closure      <host>                 # top 20 closure-size contributors
just tree         <host>                 # interactive nix-tree of the closure
just repl                               # nix repl .

# Bench / meta
just bench        [base=origin/master]   # hyperfine: eval HEAD vs base
just help                               # just -l
```

Display hint: `check` / `nb` / `build-vm` / `diff` / `diff-revs` / `build-image` all pipe through `nix-output-monitor` when stdout is a tty. Set `NO_NOM=1` (or pipe) to get plain output. `bench` is intentionally not wrapped — nom would skew eval timings.

Arch dev host: `nix shell nixpkgs#just nixpkgs#nh -c '...'`

## Constraints

### Requires confirmation before modification
- `flake.nix`
- `flake.lock`
- `pkgs/*`

### Direct modification allowed
- `modules/*`
- `scripts/*`
- `*.md`

### Common pitfalls

1. **New nix files must be git-added** — `vic/import-tree` only scans git-tracked files. Un-added nix files silently excluded from evaluation, no error.

2. **CLI tools vary by host** — Arch dev host lacks `nixos-rebuild`. Use `command -v <tool>` before running.

3. **`host-aspects` is transitional** — Compare `flake.lock` den rev with upstream changes before modifying.

## Documentation Map

| Task | Must read |
|---|---|
| Add/modify feature aspect | `docs/agents/adding-a-feature.md` + `docs/agents/den-configuration-patterns.md` |
| Quick config pattern reference | `docs/agents/den-configuration-patterns.md` (practical patterns, validation, error prevention) |
| Decide file/aspect placement | `CONTEXT.md` Modules Taxonomy |
| Den semantic work | `docs/frameworks/den.md` + local `~/workspace/nix-ref/den/docs` |
| CI / git-hooks / justfile chain | `modules/flake-parts/{git-hooks,formatter,devshell}.nix` + `.github/workflows/check.yml`; entry point `just help` |
| Terminology authority | `CONTEXT.md` |

## External References

Local refs, not in repo git, directly readable:

- `~/workspace/nix-ref/den` — den framework source
- `~/workspace/nix-ref/nixconfig` — other NixOS den configs
- `~/workspace/nix-ref/infra` — infrastructure config

## Style & Commits

- Nix formatted by `treefmt` / `alejandra`; shell by `shfmt` + `shellcheck`; lint covers `deadnix` / `statix` / `ruff-check`. The pre-commit hook runs `treefmt --fail-on-change` automatically — you do **not** need to run `just fmt` manually before committing. Manual `just fmt` / `just lint` is still useful when iterating without committing.
- Module filenames lowercase descriptive (e.g. `modules/dev/lang/python.nix`).
- Include reference style: new files use attrpath style (`{lossilk, ...}` + `lossilk.x._.y`); angle brackets `<lossilk/...>` preserved only in existing files.
- Conventional Commits: `feat(cli): ...` / `refactor(desktop): ...` / `docs: ...`.

## Workflow & Hooks

The local/CI validation chain lives in `modules/flake-parts/`:

| Module | Role |
|---|---|
| `git-hooks.nix` | Declares hooks via `cachix/git-hooks.nix` flake module. `pre-commit` runs `treefmt --fail-on-change`. Heavy `nix flake check` deferred to CI; run `just check` manually when desired. |
| `formatter.nix` | `treefmt-nix` configuration. Registers formatters **and** static linters as treefmt programs (alejandra, deadnix, statix, shfmt, shellcheck, rustfmt, black, ruff-format, ruff-check, gofmt, gofumpt, biome, just, yamlfmt, jsonfmt). Excludes `*.md`, `secrets/**`, `**/facter.json`, etc. |
| `devshell.nix` | Minimal `nix develop` shell whose only job is to run `pre-commit.installationScript` so the hooks are wired into `.git/hooks/`. |
| `.github/workflows/check.yml` | CI: `ubuntu-latest` + `determinate-nix-action@v3` + `magic-nix-cache@v14`, single `nix flake check` step. Cannot use `--no-build` (catppuccin IFD). |

Implication: a fresh clone without `nix develop` will let you commit dirty treefmt output and `nix flake check` will only fire on push. Run `nix develop` once after cloning, or accept that CI will catch it. The CI run is the authoritative gate — `--no-verify` cannot bypass it for PRs, and external PRs without the hook still hit the same check.

`justfile` recipes call the same underlying tools (`nix flake check`, `treefmt`, `nix build`, `nvd`, `nix why-depends`, `nix-tree`, `nix repl`); use them as the entry point and skip the raw `nix` invocations.

## Agent Skills

- **Domain docs**: `CONTEXT.md` + `docs/frameworks/den.md`
