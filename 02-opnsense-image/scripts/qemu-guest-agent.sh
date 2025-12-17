#!/usr/bin/env sh

set -e

# Install Qemu Guest agent
echo "Install Qemu Guest Agent to allow better reporting"
pkg install -y os-qemu-guest-agent
cat >/etc/rc.conf.local <<EOF
qemu_guest_agent_enable="YES"
qemu_guest_agent_flags="-d -v -l /var/log/qemu-ga.log"
virtio_console_load="YES"
EOF

sysrc qemu_guest_agent_enable="YES"
