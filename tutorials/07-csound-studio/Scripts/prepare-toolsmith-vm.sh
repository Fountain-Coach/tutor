#!/usr/bin/env bash
set -euo pipefail

# Prepares a QEMU VM image with LilyPond + Csound installed and systemd units
# to mount 9p shares (work, scratch) and execute a cmd=... from kernel cmdline.
#
# Result image path: ~/.toolsmith/vm/ubuntu-jammy-toolsmith.qcow2
#
# Requirements:
# - qemu-system-x86_64 and qemu-img
# - curl
# - On macOS: hdiutil (built-in). On Linux: genisoimage or xorriso.

OS_NAME="$(uname -s)"
WORK_ROOT="${HOME}/.toolsmith/vm"
IMG_NAME="ubuntu-jammy-toolsmith.qcow2"
SEED_ISO="seed.iso"
BASE_IMG="ubuntu-22.04-server-cloudimg-amd64.img"
BASE_URL="https://cloud-images.ubuntu.com/jammy/current/${BASE_IMG}"

mkdir -p "${WORK_ROOT}"
cd "${WORK_ROOT}"

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

echo "[toolsmith] Checking dependencies…"
require curl
require qemu-system-x86_64
require qemu-img

if [[ "${OS_NAME}" == "Linux" ]]; then
  if ! command -v genisoimage >/dev/null 2>&1 && ! command -v xorriso >/dev/null 2>&1; then
    echo "Missing genisoimage/xorriso. Install via: sudo apt-get install genisoimage" >&2
    exit 2
  fi
fi

echo "[toolsmith] Downloading Ubuntu cloud image (Jammy)…"
if [[ ! -f "${BASE_IMG}" ]]; then
  curl -fL "${BASE_URL}" -o "${BASE_IMG}"
else
  echo "  found ${BASE_IMG} (skipping)"
fi

echo "[toolsmith] Creating working copy qcow2…"
if [[ ! -f "${IMG_NAME}" ]]; then
  qemu-img create -f qcow2 -F qcow2 -b "${BASE_IMG}" "${IMG_NAME}"
fi

echo "[toolsmith] Preparing cloud-init seed…"
SEED_DIR="${WORK_ROOT}/seed"
rm -rf "${SEED_DIR}" && mkdir -p "${SEED_DIR}"
cat >"${SEED_DIR}/meta-data" <<META
instance-id: toolsmith-1
local-hostname: toolsmith
META

cat >"${SEED_DIR}/user-data" <<'USER'
#cloud-config
package_update: true
packages:
  - lilypond
  - csound
  - csound-utils
runcmd:
  - |
    cat >/etc/systemd/system/work.mount <<'EOF'
    [Unit]
    After=local-fs.target
    [Mount]
    What=work
    Where=/work
    Type=9p
    Options=trans=virtio,version=9p2000.L
    [Install]
    WantedBy=multi-user.target
    EOF
  - |
    cat >/etc/systemd/system/scratch.mount <<'EOF'
    [Unit]
    After=local-fs.target
    [Mount]
    What=scratch
    Where=/scratch
    Type=9p
    Options=trans=virtio,version=9p2000.L
    [Install]
    WantedBy=multi-user.target
    EOF
  - mkdir -p /work /scratch
  - systemctl enable work.mount
  - systemctl enable scratch.mount
  - |
    cat >/usr/local/bin/toolsmith-cmd.sh <<'EOS'
    #!/usr/bin/env bash
    set -euo pipefail
    cd /work || true
    # Parse cmd=... from /proc/cmdline
    CMD="$(tr ' ' '\n' </proc/cmdline | sed -n 's/^cmd=//p' | head -n1)"
    if [[ -n "${CMD}" ]]; then
      echo "[toolsmith-cmd] executing: ${CMD}"
      bash -lc "${CMD}"
    else
      echo "[toolsmith-cmd] no cmd= found; idle"
    fi
    EOS
  - chmod +x /usr/local/bin/toolsmith-cmd.sh
  - |
    cat >/etc/systemd/system/toolsmith-cmd.service <<'EOF'
    [Unit]
    Description=Toolsmith Cmd Runner
    After=network.target work.mount scratch.mount
    [Service]
    Type=oneshot
    ExecStart=/usr/local/bin/toolsmith-cmd.sh
    [Install]
    WantedBy=multi-user.target
    EOF
  - systemctl enable toolsmith-cmd.service
  - shutdown -h now
USER

echo "[toolsmith] Building seed ISO…"
if [[ "${OS_NAME}" == "Darwin" ]]; then
  hdiutil makehybrid -o "${SEED_ISO}" "${SEED_DIR}" -hfs -iso -joliet -default-volume-name CIDATA >/dev/null
else
  if command -v genisoimage >/dev/null 2>&1; then
    genisoimage -output "${SEED_ISO}" -volid CIDATA -joliet -rock "${SEED_DIR}" >/dev/null
  else
    xorriso -as genisoimage -o "${SEED_ISO}" -V CIDATA -J -r "${SEED_DIR}" >/dev/null
  fi
fi

echo "[toolsmith] Provisioning the image (first boot)…"
ACCEL=()
if [[ "${OS_NAME}" == "Darwin" ]]; then ACCEL=( -accel hvf ); else ACCEL=( -enable-kvm ); fi

qemu-system-x86_64 \
  "${ACCEL[@]}" \
  -m 2048 \
  -nographic \
  -drive file="${IMG_NAME}",if=virtio \
  -drive file="${SEED_ISO}",if=virtio,format=raw \
  -nic none \
  -serial mon:stdio || true

echo "[toolsmith] Provisioning run finished. Image ready: ${WORK_ROOT}/${IMG_NAME}"
echo "${WORK_ROOT}/${IMG_NAME}"

