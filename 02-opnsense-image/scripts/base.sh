#!/usr/bin/env sh

set -e

cd /

# NOTE(vinetos): In OPNsense, these settings are managed and replaced by OPNsense configuration
cat << EOF > /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

# NOTE(vinetos): In OPNsense, these settings are managed and replaced by OPNsense configuration
cat << EOF > /boot/loader.conf
autoboot_delay="-1"
beastie_disable="YES"
loader_logo="none"
hw.memtest.tests="0"
console="comconsole,vidconsole"
hw.vtnet.mq_disable=1
kern.timecounter.hardware=ACPI-safe
aesni_load="YES"
nvme_load="YES"
EOF

cat << EOF >> /etc/syslog.conf
*.err;kern.warning;auth.notice;mail.crit                /dev/console
EOF

# Update package to latest version
pkg update
pkg upgrade -y
opnsense-update
opnsense-update -es
pkg update
pkg upgrade -y