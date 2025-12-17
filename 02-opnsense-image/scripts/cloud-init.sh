#!/usr/bin/env sh

set -e

# Install Cloud-init for both OpenStack and Proxmox support
echo "Enabling FreeBSD repos"
# NOTE(vinetos): We lock pkg as latest version crash with multiple repos
pkg lock -y pkg
sed -i '' 's/enabled: no/enabled: yes/g' /usr/local/etc/pkg/repos/FreeBSD.conf
pkg update
echo "Install Cloud-init package"
pkg install -y py311-cloud-init
# Disable FreeBSD repos to avoid future problems
sed -i '' 's/enabled: yes/enabled: no/g' /usr/local/etc/pkg/repos/FreeBSD.conf
pkg unlock -y pkg

echo "Generating cloud-init config file"
mkdir -p /etc/cloud/cloud.cfg.d/

cat <<EOF >/etc/cloud/cloud.cfg.d/01-cloud.cfg
#cloud-config
# The top level settings are used as module
# and system configuration.
syslog_fix_perms: root:wheel

# If this is set, 'root' will not be able to ssh in and they
# will get a message to login instead as the default $user
disable_root: false

# This will cause the set+update hostname module to not operate (if true)
preserve_hostname: false

# If you use datasource_list array, keep array items in a single line.
# If you use multi line array, ds-identify script won't read array items.
# This should not be required, but leave it in place until the real cause of
# not finding -any- datasources is resolved.
# Prioritize NoCloud and ConfigDrive for Proxmox compatibility
datasource_list: ['NoCloud', 'ConfigDrive', 'OpenStack', 'Ec2', 'Azure']
# Example datasource config
# datasource:
#    Ec2:
#      metadata_urls: [ 'blah.com' ]
#      timeout: 5 # (defaults to 50 seconds)
#      max_wait: 10 # (defaults to 120 seconds)


# The modules that run in the 'init' stage
cloud_init_modules:
 - migrator
 - seed_random
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - users-groups
 - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
 - ssh-import-id
 - keyboard
 - locale
 - set-passwords
 - timezone
 - disable-ec2-metadata
 - runcmd

# The modules that run in the 'final' stage
cloud_final_modules:
 - package-update-upgrade-install
 - write-files-deferred
 - puppet
 - chef
 - ansible
 - mcollective
 - salt-minion
 - reset_rmc
 - refresh_rmc_and_interface
 - rightscale_userdata
 - scripts-vendor
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - install-hotplug
 - phone-home
 - final-message
 - power-state-change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
   # This will affect which distro class gets used
   distro: freebsd
   network:
      renderers: ['freebsd']
growpart:
   mode: auto
   devices:
      - /dev/vtbd0p3
      - /dev/da0p3
      - /


EOF

sysrc cloudinit_enable="YES"
