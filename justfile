set shell := ["bash", "-c"]

# Default recipe
default: check

# List available recipes
help:
    just -l

# nh os switch [args]  (e.g. just switch, just switch .#nixos-wsl, just switch .#nixos-wsl --ask)
switch *args:
    nh os switch {{ args }}

# nh os build [args]
build *args:
    nh os build {{ args }}

# nix build <host>'s VM image to ./result-<host>/  (e.g. just build-vm nixos-niri-dms-vm)
build-vm host *args:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.vm -o result-{{ host }} {{ args }}

# nix flake check [args]
check *args:
    nix flake check {{ args }}

# build-vm <host> 后 boot
test-vm host: (build-vm host) (run-vm host)

# nix fmt [args]
fmt *args:
    nix fmt {{ args }}

# boot ./result-<host>/bin/run-<host>-vm (Arch: 用 host qemu 替代 nix-store qemu)
run-vm host:
    RESULT="$PWD/result-{{ host }}" scripts/run-vm-arch.sh {{ host }}

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
