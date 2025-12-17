#!/bin/sh
# This script is an rc script based on the one from Remy van Elst.

# Copyright (C) 2018 Remy van Elst.
# Author: Remy van Elst for https://www.cloudvps.com
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

# This script sets the root password
# to a random password generated on the instance
# and posts that if possible to the openstack
# metadata service for nova get-password.

# PROVIDE: firstboot
# REQUIRE: LOGIN DAEMON NETWORKING
# KEYWORD: nojail

. /etc/rc.subr

name=firstboot
rcvar=firstboot_enable

start_cmd="${name}_start"

log() {
  MSG="$1"
  echo "[opnsense-password-generator] ""$MSG" > /dev/ttyu0
  logger "[opnsense-password-generator] ""$MSG"
}

detect_cloud_platform() {
  # Try to detect which cloud platform we're running on
  if curl -s -f --connect-timeout 2 http://169.254.169.254/openstack/latest/meta_data.json >/dev/null 2>&1; then
    echo "openstack"
  elif curl -s -f --connect-timeout 2 http://169.254.169.254/latest/meta-data/ >/dev/null 2>&1; then
    echo "ec2-compatible"
  elif [ -f /var/lib/cloud/instance/datasource ]; then
    # Check cloud-init datasource
    if grep -q "DataSourceNoCloud" /var/lib/cloud/instance/datasource 2>/dev/null; then
      echo "nocloud"
    elif grep -q "DataSourceConfigDrive" /var/lib/cloud/instance/datasource 2>/dev/null; then
      echo "configdrive"
    else
      echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

get_ssh_key_from_cloud_init() {
  # Try to get SSH key from cloud-init data
  local keyfile="$1"
  
  # Check if cloud-init has already processed authorized keys
  if [ -f /var/lib/cloud/instance/user-data.txt ]; then
    # Extract SSH key from user-data if present
    grep -A 1 "ssh_authorized_keys:" /var/lib/cloud/instance/user-data.txt | tail -n 1 | sed 's/^[[:space:]]*-[[:space:]]*//' > "$keyfile" 2>/dev/null
    if [ -s "$keyfile" ]; then
      return 0
    fi
  fi
  
  # Try cloud-init's public keys data
  if [ -f /var/lib/cloud/instance/obj.pkl ] || [ -d /var/lib/cloud/instances ]; then
    # Look for authorized_keys that cloud-init might have set up
    if [ -f /root/.ssh/authorized_keys ]; then
      head -n 1 /root/.ssh/authorized_keys > "$keyfile"
      if [ -s "$keyfile" ]; then
        return 0
      fi
    fi
  fi
  
  return 1
}

firstboot_start() {

  log "Started set root password and post to metadata service"

  if [ -e "/var/lib/cloud/instance/rootpassword-random" ]; then
    log "Password has already been set."
    # script already ran on this instance.
    # /var/lib/cloud/instance/ is a symlink to /var/lib/cloud/instances/$instance_uuid
    # if user creates an image and deploys image, this must run again, that file will not exist
    exit 0
  fi

  export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin

  # Two tmp files for the SSH and SSL pubkey
  SSH_KEYFILE=$(mktemp)
  SSL_KEYFILE=$(mktemp)
  
  # Detect cloud platform
  CLOUD_PLATFORM=$(detect_cloud_platform)
  log "Detected cloud platform: $CLOUD_PLATFORM"

  # get the ssh public key from the metadata server or cloud-init
  log "Retrieve public key from metadata server"
  
  case "$CLOUD_PLATFORM" in
    openstack|ec2-compatible)
      curl -s -f http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key >$SSH_KEYFILE
      if [ $? != 0 ]; then
        log "Instance public SSH key not found on metadata service. Trying cloud-init data."
        get_ssh_key_from_cloud_init "$SSH_KEYFILE"
      fi
      ;;
    nocloud|configdrive|*)
      log "Using cloud-init datasource for SSH key"
      get_ssh_key_from_cloud_init "$SSH_KEYFILE"
      ;;
  esac
  
  if [ ! -s "$SSH_KEYFILE" ]; then
    log "Instance public SSH key not found. Unable to set password encryption."
    # Clean up and exit - cloud-init should have handled SSH keys already
    rm -rf $SSH_KEYFILE $SSL_KEYFILE
    exit 0
  fi

  # NOTE(vinetos): OPNsense specific addition of public key for ssh connection
  log "Encoding key in base64"
  PUB_KEY_ENCODED=$(cat "$SSH_KEYFILE" | base64 | tr -d \\n)
  log "Updating config.xml"
  sed -i '' 's|<authorizedkeys>autochangeme_authorizedkeys==</authorizedkeys>|<authorizedkeys>'"${PUB_KEY_ENCODED}"'</authorizedkeys>|g' /conf/config.xml

  # generate a random password
  # our images have have ged installed so should have enough entropy at boot.
  log "Generate a random password for root user"
  RANDOM_PASSWORD="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -c 30)"
  if [ -z ${RANDOM_PASSWORD} ]; then
    log "unable to generate random password."
    exit 0
  fi

  # set the root password to this random password
  # add any other password changes like admin for DirectAdmin.
  # NOTE(vinetos): OPNsense specific password change
  log "Change password for root user"
  printf 'y\n'"$RANDOM_PASSWORD"'\n'"$RANDOM_PASSWORD" | opnsense-shell password

  if [ -s "$SSH_KEYFILE" ]; then
    # convert the ssh pubkey to an SSL keyfile so that we can use it to encrypt with OpenSSL
    log "Convert ssh pubkey to SSL format to encode and upload password"
    ssh-keygen -e -f $SSH_KEYFILE -m PKCS8 >$SSL_KEYFILE
    log "Encode generated password"
    ENCRYPTED=$(echo "$RANDOM_PASSWORD" | openssl rsautl -encrypt -pubin -inkey $SSL_KEYFILE -keyform PEM | openssl base64 -e -A)
    
    # Post encrypted blob to metadata service if running on OpenStack
    if [ "$CLOUD_PLATFORM" = "openstack" ]; then
      log "Post encoded password to OpenStack metadata-server"
      curl -s -X POST http://169.254.169.254/openstack/2013-04-04/password -d $ENCRYPTED 2>&1 >/dev/null || true
    else
      log "Non-OpenStack platform detected. Encrypted password: $ENCRYPTED"
      log "Note: For Proxmox, retrieve password via: qm guest exec <vmid> -- cat /var/log/messages | grep 'Encrypted password'"
    fi
  fi

  log "Cleaning up data"
  # housekeeping
  rm -rf $SSH_KEYFILE $SSL_KEYFILE

  # Make sure the script wont be run again by error
  mkdir -p /var/lib/cloud/instance/
  touch /var/lib/cloud/instance/rootpassword-random
  sysrc firstboot_enable="FALSE"

  #sync the hard disk
  sync

  #sleep to make sure everything is done
  sleep 1

  # Clean up history file
  rm /root/.history

  # NOTE(vinetos): Reload OPNsense to apply our modifications
  log "Reloading opensense"
  opnsense-shell reload
}

load_rc_config $name
run_rc_command "$1"
