set shell := ["bash", "-c"]

# Default recipe
default: check

# List available recipes
help:
    just -l

# nh os switch [args]  (e.g. just switch, just switch .#nixos-wsl, just switch .#nixos-wsl --ask)
# nh uses nix-output-monitor by default; pass --no-nom to disable.
switch *args:
    nh os switch {{ args }}

# nh os build [args]
# nh uses nix-output-monitor by default; pass --no-nom to disable.
build *args:
    nh os build {{ args }}

# nix build <host>'s VM image to /tmp/result-<host>/  (e.g. just build-vm nixos-niri-dms-vm)
build-vm host *args:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.vm -o /tmp/result-{{ host }} {{ args }}

# nix flake check — runs through nom by default for nicer build progress.
# Set NO_NOM=1 to fall back to plain output (CI / non-tty).
check *args:
    set -o pipefail; \
    if [ -n "${NO_NOM:-}" ]; then \
      nix flake check {{ args }}; \
    else \
      nix flake check --log-format internal-json -v {{ args }} \
        |& nix run nixpkgs#nix-output-monitor; \
    fi

# nix build wrapped with nom progress (NO_NOM=1 to disable).
# Example: just nb .#nixosConfigurations.nixos-wsl.config.system.build.toplevel
nb *args:
    set -o pipefail; \
    if [ -n "${NO_NOM:-}" ]; then \
      nix build {{ args }}; \
    else \
      nix build --log-format internal-json -v {{ args }} \
        |& nix run nixpkgs#nix-output-monitor; \
    fi

# build-vm <host> 后 boot
test-vm host: (build-vm host) (run-vm host)

# Format only (alejandra, shfmt, rustfmt, black, gofmt, biome, yamlfmt, jsonfmt, etc.)
# Skips linters (deadnix, statix, shellcheck, ruff-check)
fmt *args:
    nix fmt -- --formatters alejandra,shfmt,rustfmt,black,ruff-format,gofmt,gofumpt,biome,just,yamlfmt,jsonfmt {{ args }}

# Lint only (deadnix, statix, shellcheck, ruff-check)
# Exits non-zero on findings
lint *args:
    nix fmt -- --fail-on-change --formatters deadnix,statix,shellcheck,ruff-check {{ args }}

# boot /tmp/result-<host>/bin/run-<host>-vm (Arch: 用 host qemu 替代 nix-store qemu)
run-vm host:
    RESULT=/tmp/result-{{ host }} scripts/run-vm-arch.sh {{ host }}

# nix flake update [args]
update *args:
    nix flake update {{ args }}

# nh clean <subcommand> [args]  (default subcommand: all; weekly auto service also runs)
clean *args="all":
    nh clean {{ args }}

# Check formatting (exits non-zero if unformatted)
fmt-check:
    nix fmt -- --fail-on-change

# Run all checks: formatting + flake check
check-all: fmt-check check

# ─── Change-impact tools ──────────────────────────────────────────────────
# Build <host>'s system and diff against the currently running system.
# Useful before `just switch` to preview package/version changes.
# Example: just diff nixos-wsl
diff host *args:
    @echo "Building .#nixosConfigurations.{{ host }}.config.system.build.toplevel ..."
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
      --out-link /tmp/result-diff-{{ host }} {{ args }}
    nix run nixpkgs#nvd -- diff /run/current-system /tmp/result-diff-{{ host }}

# Diff <host>'s system between a git ref and the current working tree.
# Useful for "what did I change since <ref>".
# Example: just diff-revs nixos-wsl HEAD~5
diff-revs host ref:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
      --out-link /tmp/result-{{ host }}-now
    nix build "git+file://$PWD?rev=$(git rev-parse {{ ref }})#nixosConfigurations.{{ host }}.config.system.build.toplevel" \
      --out-link /tmp/result-{{ host }}-base
    nix run nixpkgs#nvd -- diff /tmp/result-{{ host }}-base /tmp/result-{{ host }}-now

# Why does <host>'s system depend on <attr>? <attr> is any installable or store path.
# Example: just why nixos-wsl /nix/store/...-firefox-...
why host attr:
    nix why-depends .#nixosConfigurations.{{ host }}.config.system.build.toplevel {{ attr }}

# Top 20 contributors to <host>'s system closure size.
closure host:
    nix path-info -rsSh .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
      | sort -hk2 | tail -20

# Interactive dependency-tree explorer for <host>'s system closure.
tree host:
    nix run nixpkgs#nix-tree -- .#nixosConfigurations.{{ host }}.config.system.build.toplevel

# Interactive nix repl with this flake loaded
repl *args:
    nix repl . {{ args }}

# List available disk image variants for a host  (e.g. just list-image-variants nixos-wsl)
list-image-variants host:
    nix eval .#nixosConfigurations.{{ host }}.config.system.build.images --apply 'builtins.attrNames' --json 2>/dev/null | nix run nixpkgs#jq -- -r '.[]'

# Build a platform-specific disk image. Requires explicit host AND variant — no defaults.
# Usage: just build-image <host> <variant> [extra nixos-rebuild flags]
# Example: just build-image nixos-wsl amazon
# WARNING: images can be multiple GB. Run `just list-image-variants <host>` first.
build-image host variant *args:
    @echo "============================================"
    @echo " Building {{ variant }} disk image for {{ host }}"
    @echo " Target: nixos-rebuild build-image --flake .#{{ host }} --image-variant {{ variant }}"
    @echo "============================================"
    nixos-rebuild build-image --flake .#{{ host }} --image-variant {{ variant }} {{ args }}

# Benchmark eval speed: HEAD vs base branch (requires hyperfine)
bench base="refs/remotes/origin/master" *args:
    hyperfine -w 2 {{ args }} \
      -n head "nix eval .#nixosConfigurations --apply 'builtins.attrNames' 2>&1 | tail -1" \
      -n base "nix eval --override-input self git+file://$PWD?rev=$$(git rev-parse {{ base }}) .#nixosConfigurations --apply 'builtins.attrNames' 2>&1 | tail -1"
