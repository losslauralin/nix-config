# NixOS Configuration Agent Guide

NixOS / `denful/den` aspect-oriented architecture + `flake-parts`. Terminology & mental model in `CONTEXT.md`.
Local namespace: `lossilk` (registered in `modules/den.nix`).

## Commands (must use just wrappers)

**Never call nix/nh/nixos-rebuild directly. Always use justfile wrappers.**

```
just              # validate (default)
just check        # validate
just fmt          # format
just build        # build
just switch       # deploy
just build-vm     # build VM
just test-vm      # test VM
just run-vm       # run VM
just update       # update flake
just clean        # clean
just fmt-check    # format check (no changes)
just check-all    # fmt-check + check
```

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
| Terminology authority | `CONTEXT.md` |

## External References

Local refs, not in repo git, directly readable:

- `~/workspace/nix-ref/den` — den framework source
- `~/workspace/nix-ref/nixconfig` — other NixOS den configs
- `~/workspace/nix-ref/infra` — infrastructure config

## Style & Commits

- Nix formatted by treefmt/`alejandra`; shell scripts by `shfmt` + `shellcheck`. Run `just fmt` before commit.
- Module filenames lowercase descriptive (e.g. `modules/dev/lang/python.nix`).
- Include reference style: new files use attrpath style (`{lossilk, ...}` + `lossilk.x._.y`); angle brackets `<lossilk/...>` preserved only in existing files.
- Conventional Commits: `feat(cli): ...` / `refactor(desktop): ...` / `docs: ...`.

## Agent Skills

- **Domain docs**: `CONTEXT.md` + `docs/frameworks/den.md`
