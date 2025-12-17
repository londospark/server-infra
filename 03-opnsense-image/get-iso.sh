#!/usr/bin/env sh

set -e

# Set defaults if not provided
VERSION="${PKR_VAR_VERSION:-25.7}"
MIRROR="${PKR_VAR_MIRROR:-https://mirror.init7.net/opnsense}"

echo "Download OPNsense ${VERSION} from ${MIRROR}"

download() {
  mkdir -p iso

  ISO_FILE="iso/OPNsense-${VERSION}-dvd-amd64.iso"
  BZ2_FILE="${ISO_FILE}.bz2"

  # Check if ISO already exists
  if [ -f "${ISO_FILE}" ]; then
    echo "ISO already exists: ${ISO_FILE}"
    echo "Skipping download. Remove the file to re-download."
    return 0
  fi

  # Check if compressed file exists
  if [ -f "${BZ2_FILE}" ]; then
    echo "Compressed ISO already exists: ${BZ2_FILE}"
    echo "Decompressing ISO..."
    bzip2 -d "${BZ2_FILE}"
    echo "ISO ready: ${ISO_FILE}"
    return 0
  fi

  echo "Downloading OPNsense-${VERSION}-dvd-amd64.iso.bz2..."
  curl --output "${BZ2_FILE}" \
    "${MIRROR}/releases/${VERSION}/OPNsense-${VERSION}-dvd-amd64.iso.bz2"

  echo "Decompressing ISO..."
  bzip2 -d "${BZ2_FILE}"
  
  echo "ISO ready: ${ISO_FILE}"
}

download
