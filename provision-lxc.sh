#!/usr/bin/env bash
# provision-lxc.sh — Run this FROM YOUR LOCAL MACHINE (not from a remote container)
# Usage: bash provision-lxc.sh
# Requires: sshpass installed locally (brew install sshpass / apt install sshpass)

set -euo pipefail

PROXMOX_HOST="192.168.40.202"
PROXMOX_USER="root"
PROXMOX_PASS='nur34GUSp$$'
REPO_URL="https://github.com/601ITGuy/mkdocs-material.git"
LXC_HOSTNAME="mkdocs-material"
LXC_MEMORY=2048
LXC_SWAP=512
LXC_CORES=4
LXC_DISK=16

ssh_pve() {
  sshpass -p "$PROXMOX_PASS" ssh -o StrictHostKeyChecking=no \
    -o ConnectTimeout=15 "$PROXMOX_USER@$PROXMOX_HOST" "$@"
}

echo "==> [1/6] Probing Proxmox environment..."
ENV_INFO=$(ssh_pve "
  echo NODE=\$(hostname)
  echo NEXTID=\$(pvesh get /cluster/nextid 2>/dev/null || echo 200)
  # Detect first available storage pool that supports rootdir
  STORAGE=\$(pvesm status --content rootdir 2>/dev/null | awk 'NR==2{print \$1}')
  [ -z \"\$STORAGE\" ] && STORAGE=local-lvm
  echo STORAGE=\$STORAGE
  # Detect active bridge
  BRIDGE=\$(ip link show type bridge 2>/dev/null | awk -F': ' '/^[0-9]+/{print \$2}' | head -1)
  [ -z \"\$BRIDGE\" ] && BRIDGE=vmbr0
  echo BRIDGE=\$BRIDGE
  # Check if Ubuntu 22.04 template exists
  TMPL=\$(pveam list local 2>/dev/null | grep 'ubuntu-22.04' | head -1 | awk '{print \$1}')
  echo TMPL=\$TMPL
")

eval "$ENV_INFO"
echo "  Node:    $NODE"
echo "  VMID:    $NEXTID"
echo "  Storage: $STORAGE"
echo "  Bridge:  $BRIDGE"
echo "  Template: ${TMPL:-<not found>}"

echo ""
echo "==> [2/6] Ensuring Ubuntu 22.04 template is available..."
if [ -z "${TMPL:-}" ]; then
  ssh_pve "pveam update && pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  TMPL="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
fi
echo "  Using template: $TMPL"

echo ""
echo "==> [3/6] Creating LXC $NEXTID ($LXC_HOSTNAME)..."
ssh_pve "pct create $NEXTID $TMPL \
  --hostname $LXC_HOSTNAME \
  --memory $LXC_MEMORY \
  --swap $LXC_SWAP \
  --cores $LXC_CORES \
  --rootfs ${STORAGE}:${LXC_DISK} \
  --net0 name=eth0,bridge=${BRIDGE},ip=dhcp \
  --unprivileged 1 \
  --features nesting=1 \
  --onboot 1"

echo ""
echo "==> [4/6] Starting LXC and waiting for network..."
ssh_pve "pct start $NEXTID"
sleep 10   # give container time to boot and get DHCP lease

echo ""
echo "==> [5/6] Provisioning inside LXC (this takes 3-5 minutes)..."
ssh_pve "pct exec $NEXTID -- bash -c '
set -e
export DEBIAN_FRONTEND=noninteractive

echo \"--- apt update ---\"
apt-get update -q

echo \"--- Installing system packages ---\"
apt-get install -y -q \
  build-essential curl git ca-certificates gnupg \
  python3.11 python3.11-dev python3.11-venv python3-pip \
  libcairo2-dev libffi-dev zlib1g-dev libjpeg-dev libfreetype6-dev \
  pngquant

echo \"--- Installing Node.js 18 ---\"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - 2>&1 | tail -5
apt-get install -y nodejs

echo \"--- Node / Python versions ---\"
node --version
python3 --version

echo \"--- Cloning repository ---\"
git clone --depth=1 $REPO_URL /opt/mkdocs-material
cd /opt/mkdocs-material

echo \"--- Installing Python packages ---\"
pip install --break-system-packages -e \".[recommended,imaging]\" 2>&1 | tail -10

echo \"--- Installing Node dependencies ---\"
npm install 2>&1 | tail -5

echo \"--- Building frontend assets (optimized) ---\"
npm run build 2>&1 | tail -10

echo \"--- All done! ---\"
mkdocs --version
'"

echo ""
echo "==> [6/6] Verifying installation..."
ssh_pve "pct exec $NEXTID -- bash -c '
  cd /opt/mkdocs-material
  echo \"mkdocs: \$(mkdocs --version)\"
  echo \"node:   \$(node --version)\"
  echo \"python: \$(python3 --version)\"
  echo \"npm:    \$(npm --version)\"
  # Quick smoke-test build
  mkdocs build --quiet && echo \"mkdocs build: OK\" || echo \"mkdocs build: FAILED\"
'"

LXC_IP=$(ssh_pve "pct exec $NEXTID -- bash -c \"ip -4 addr show eth0 | grep -oP '(?<=inet )[^/]+'\"" 2>/dev/null || echo "unknown")

echo ""
echo "=============================="
echo " LXC provisioned successfully"
echo "=============================="
echo "  VMID:    $NEXTID"
echo "  IP:      $LXC_IP"
echo ""
echo " To serve the docs (inside the LXC):"
echo "   pct exec $NEXTID -- bash -c 'cd /opt/mkdocs-material && mkdocs serve --dev-addr 0.0.0.0:8000'"
echo " Then open: http://${LXC_IP}:8000"
echo ""
