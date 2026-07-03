set shell := ["bash", "-c"]

# Default recipe
default: check

# List available recipes
help:
    just -l

# NH NixOS switch workflow [args]  (e.g. just os-switch .#nixos-wsl --ask)
os-switch *args:
    nh os switch {{ args }}

# NH NixOS build workflow [args]
os-build *args:
    nh os build {{ args }}

# Generic nix build wrapped with nom progress (NO_NOM=1 or non-tty disables).
build *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "${NO_NOM:-}" ] || [ ! -t 1 ]; then
      exec nix build {{ args }}
    fi
    if nom_cmd=$(command -v nom 2>/dev/null); then
      nix build --log-format internal-json -v {{ args }} |& "$nom_cmd" --json
    else
      nom_out=$(nix build --no-link --print-out-paths nixpkgs#nix-output-monitor)
      nix build --log-format internal-json -v {{ args }} |& "$nom_out/bin/nom" --json
    fi

# nix build <host>'s VM image to /tmp/result-<host>/  (e.g. just build-vm nixos-niri-dms-vm)
# Wrapped with nom (NO_NOM=1 or non-tty disables).
build-vm host *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "${NO_NOM:-}" ] || [ ! -t 1 ]; then
      exec nix build .#nixosConfigurations.{{ host }}.config.system.build.vm \
        -o /tmp/result-{{ host }} {{ args }}
    fi
    if nom_cmd=$(command -v nom 2>/dev/null); then
      nix build --log-format internal-json -v \
        .#nixosConfigurations.{{ host }}.config.system.build.vm \
        -o /tmp/result-{{ host }} {{ args }} |& "$nom_cmd" --json
    else
      nom_out=$(nix build --no-link --print-out-paths nixpkgs#nix-output-monitor)
      PATH="$nom_out/bin:$PATH" \
        nix build --log-format internal-json -v \
          .#nixosConfigurations.{{ host }}.config.system.build.vm \
          -o /tmp/result-{{ host }} {{ args }} |& "$nom_out/bin/nom" --json
    fi

# nix flake check — runs through nom by default for nicer build progress.
# Falls back to plain output when stdout is not a tty (CI, pipes) or NO_NOM=1.
check *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "${NO_NOM:-}" ] || [ ! -t 1 ]; then
      exec nix flake check {{ args }}
    fi
    if nom_cmd=$(command -v nom 2>/dev/null); then
      nix flake check --log-format internal-json -v {{ args }} |& "$nom_cmd" --json
    else
      nom_out=$(nix build --no-link --print-out-paths nixpkgs#nix-output-monitor)
      nix flake check --log-format internal-json -v {{ args }} |& "$nom_out/bin/nom" --json
    fi

# Generic nix build with --no-link, wrapped with nom progress (NO_NOM=1 or non-tty disables).
# Example: just nb .#nixosConfigurations.nixos-wsl.config.system.build.toplevel
nb *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "${NO_NOM:-}" ] || [ ! -t 1 ]; then
      exec nix build --no-link {{ args }}
    fi
    if nom_cmd=$(command -v nom 2>/dev/null); then
      nix build --no-link --log-format internal-json -v {{ args }} |& "$nom_cmd" --json
    else
      nom_out=$(nix build --no-link --print-out-paths nixpkgs#nix-output-monitor)
      nix build --no-link --log-format internal-json -v {{ args }} |& "$nom_out/bin/nom" --json
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

# NH store/profile cleanup workflow. Default subcommand: all.
store-clean *args="all":
    nh clean {{ args }}

# Check formatting (exits non-zero if unformatted)
fmt-check:
    nix fmt -- --fail-on-change

# Run all checks: formatting + flake check
check-all: fmt-check check

# ─── Change-impact tools ──────────────────────────────────────────────────
# Build <host>'s system and diff against the currently running system.
# Useful before `just os-switch` to preview package/version changes.
# Build step wrapped with nom; nvd diff prints itself afterwards.
# Example: just diff nixos-wsl
diff host *args:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Building .#nixosConfigurations.{{ host }}.config.system.build.toplevel ..."
    if [ -n "${NO_NOM:-}" ] || [ ! -t 1 ]; then
      nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
        --out-link /tmp/result-diff-{{ host }} {{ args }}
    else
      if nom_cmd=$(command -v nom 2>/dev/null); then
        nix build --log-format internal-json -v \
          .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
          --out-link /tmp/result-diff-{{ host }} {{ args }} |& "$nom_cmd" --json
      else
        nom_out=$(nix build --no-link --print-out-paths nixpkgs#nix-output-monitor)
        nix build --log-format internal-json -v \
          .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
          --out-link /tmp/result-diff-{{ host }} {{ args }} |& "$nom_out/bin/nom" --json
      fi
    fi
    if command -v nvd >/dev/null; then
      nvd diff /run/current-system /tmp/result-diff-{{ host }}
    else
      nix run nixpkgs#nvd -- diff /run/current-system /tmp/result-diff-{{ host }}
    fi

# Diff <host>'s system between a git ref and the current working tree.
# Useful for "what did I change since <ref>". Both build steps go through nom.
# Example: just diff-revs nixos-wsl HEAD~5
diff-revs host ref:
    #!/usr/bin/env bash
    set -euo pipefail
    base_ref=$(git rev-parse {{ ref }})
    if [ -n "${NO_NOM:-}" ] || [ ! -t 1 ]; then
      nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
        --out-link /tmp/result-{{ host }}-now
      nix build "git+file://$PWD?rev=$base_ref#nixosConfigurations.{{ host }}.config.system.build.toplevel" \
        --out-link /tmp/result-{{ host }}-base
    else
      if nom_cmd=$(command -v nom 2>/dev/null); then
        nix build --log-format internal-json -v \
          .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
          --out-link /tmp/result-{{ host }}-now |& "$nom_cmd" --json
        nix build --log-format internal-json -v \
          "git+file://$PWD?rev=$base_ref#nixosConfigurations.{{ host }}.config.system.build.toplevel" \
          --out-link /tmp/result-{{ host }}-base |& "$nom_cmd" --json
      else
        nom_out=$(nix build --no-link --print-out-paths nixpkgs#nix-output-monitor)
        nix build --log-format internal-json -v \
          .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
          --out-link /tmp/result-{{ host }}-now |& "$nom_out/bin/nom" --json
        nix build --log-format internal-json -v \
          "git+file://$PWD?rev=$base_ref#nixosConfigurations.{{ host }}.config.system.build.toplevel" \
          --out-link /tmp/result-{{ host }}-base |& "$nom_out/bin/nom" --json
      fi
    fi
    if command -v nvd >/dev/null; then
      nvd diff /tmp/result-{{ host }}-base /tmp/result-{{ host }}-now
    else
      nix run nixpkgs#nvd -- diff /tmp/result-{{ host }}-base /tmp/result-{{ host }}-now
    fi

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
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v nix-tree >/dev/null; then
      nix-tree .#nixosConfigurations.{{ host }}.config.system.build.toplevel
    else
      nix run nixpkgs#nix-tree -- .#nixosConfigurations.{{ host }}.config.system.build.toplevel
    fi

# Interactive nix repl with this flake loaded
repl *args:
    nix repl . {{ args }}

# List available disk image variants for a host  (e.g. just list-image-variants nixos-wsl)
list-image-variants host:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v jq >/dev/null; then
      nix eval .#nixosConfigurations.{{ host }}.config.system.build.images --apply 'builtins.attrNames' --json 2>/dev/null | jq -r '.[]'
    else
      nix eval .#nixosConfigurations.{{ host }}.config.system.build.images --apply 'builtins.attrNames' --json 2>/dev/null | nix run nixpkgs#jq -- -r '.[]'
    fi

# Build a platform-specific disk image. Requires explicit host AND variant — no defaults.
# Usage: just build-image <host> <variant> [extra nixos-rebuild flags]
# Example: just build-image nixos-wsl amazon
# WARNING: images can be multiple GB. Run `just list-image-variants <host>` first.
# Wrapped with nom in passthrough mode (nixos-rebuild doesn't speak internal-json).
build-image host variant *args:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "============================================"
    echo " Building {{ variant }} disk image for {{ host }}"
    echo " Target: nixos-rebuild build-image --flake .#{{ host }} --image-variant {{ variant }}"
    echo "============================================"
    if [ -n "${NO_NOM:-}" ] || [ ! -t 1 ]; then
      exec nixos-rebuild build-image --flake .#{{ host }} --image-variant {{ variant }} {{ args }}
    fi
    if nom_cmd=$(command -v nom 2>/dev/null); then
      nixos-rebuild build-image --flake .#{{ host }} --image-variant {{ variant }} {{ args }} |& "$nom_cmd"
    else
      nom_out=$(nix build --no-link --print-out-paths nixpkgs#nix-output-monitor)
      nixos-rebuild build-image --flake .#{{ host }} --image-variant {{ variant }} {{ args }} |& "$nom_out/bin/nom"
    fi

# Benchmark eval speed: HEAD vs base branch (requires hyperfine)
# Note: NOT wrapped with nom — pure evaluation, and nom would skew timings.
bench base="refs/remotes/origin/master" *args:
    hyperfine -w 2 {{ args }} \
      -n head "nix eval .#nixosConfigurations --apply 'builtins.attrNames' 2>&1 | tail -1" \
      -n base "nix eval --override-input self git+file://$PWD?rev=$$(git rev-parse {{ base }}) .#nixosConfigurations --apply 'builtins.attrNames' 2>&1 | tail -1"
