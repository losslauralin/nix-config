#!/usr/bin/env bash
# scripts/run-vm-arch.sh
#
# Run a niri-VM host using Arch host's /usr/bin/qemu-system-x86_64 instead of the
# nix-store qemu (which can't find /run/opengl-driver on non-NixOS hosts and
# breaks virtio-vga-gl GL passthrough — see modules/system/vm.nix).
#
# Workflow:
#   just build-vm <host>                                # builds to /tmp/result-<host>
#   just run-vm <host>                                  # boot with qcow2 in /tmp/<host>.qcow2
#   DISPLAY_FALLBACK=1 just run-vm <host>               # software rendering fallback
#   just run-vm <host> -snapshot                        # extra qemu args passed through
#
# Multi-host smoke test (Noctalia vs DMS):
#   just build-vm nixos-niri-vm
#   just run-vm nixos-niri-vm
#   just build-vm nixos-niri-dms-vm
#   just run-vm nixos-niri-dms-vm
#
# Diagnostics:
#   - Serial console output streams to the launching terminal (vm.nix wires
#     -serial mon:stdio + kernel console=ttyS0). Even if display is black,
#     kernel + greetd + niri logs still appear here.
#   - SSH into the VM once it's up: ssh -p 2222 loss@localhost  (password: "password")

set -euo pipefail

# shellcheck disable=SC2034
REPO=$(cd "$(dirname "$0")/.." && pwd)
HOST="${1:-nixos-niri-vm}"
# Strip the host arg from $@ so remaining args pass through to qemu
if [[ $# -ge 1 ]]; then shift; fi

RESULT="${RESULT:-/tmp/result-${HOST}}"
RUNNER="$RESULT/bin/run-${HOST}-vm"

if [[ ! -x $RUNNER ]]; then
  cat >&2 <<EOF
Missing $RUNNER — build the VM first:
  sudo nix build .#nixosConfigurations.${HOST}.config.system.build.vm
(or pass RESULT=/path/to/other-result if the symlink isn't \$REPO/result)
EOF
  exit 1
fi

# Work on a writable copy so we can sed-substitute paths without touching the
# /nix/store result.
WORK=$(mktemp -d /tmp/run-vm-arch.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
install -m 0755 "$RUNNER" "$WORK/run.sh"

# Replace nix-store qemu binaries with Arch host equivalents (qemu 10.x via
# pacman qemu-base + qemu-system-x86 + qemu-hw-display-virtio-vga-gl).
sed -i \
  -e 's#/nix/store/[a-z0-9]\+-qemu-host-cpu-only[^/]*/bin/qemu-system-x86_64#/usr/bin/qemu-system-x86_64#g' \
  -e 's#/nix/store/[a-z0-9]\+-qemu-host-cpu-only[^/]*/bin/qemu-img#/usr/bin/qemu-img#g' \
  "$WORK/run.sh"

# Software-rendering fallback: isolates virtio-vga-gl GL protocol failures
# from niri's own "no outputs" issues. Used to bisect (a) qemu GL didn't
# negotiate vs (c) niri found no DRM connector.
if [[ ${DISPLAY_FALLBACK:-0} == "1" ]]; then
  sed -i \
    -e 's#-device virtio-vga-gl#-vga std#g' \
    -e 's#-display gtk,gl=on,show-cursor=on#-display gtk,gl=off,show-cursor=on#g' \
    "$WORK/run.sh"
  echo "[run-vm-arch] DISPLAY_FALLBACK=1: forcing software rendering (-vga std, gl=off)" >&2
fi

# Default qcow2 to /tmp instead of CWD (nix-generated runner uses ./<host>.qcow2)
export NIX_DISK_IMAGE="${NIX_DISK_IMAGE:-/tmp/${HOST}.qcow2}"

echo "[run-vm-arch] using $(grep -oE '/usr/bin/qemu-system-x86_64' "$WORK/run.sh" | head -1)" >&2
echo "[run-vm-arch] disk image: $NIX_DISK_IMAGE" >&2
echo "[run-vm-arch] serial console: this terminal (kernel console=ttyS0 + -serial mon:stdio)" >&2
echo "[run-vm-arch] ssh once up: ssh -p 2222 loss@localhost" >&2

exec bash "$WORK/run.sh" "$@"
