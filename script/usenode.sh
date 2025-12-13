#!/bin/bash
# Switch Node.js to a mounted version. Supports directory or tar.gz under /opt/ext/node.
# Usage: usenode <major> (e.g. 14|16|18|20|22)
# Can be sourced: source usenode <major> or . usenode <major>
# Detect if script is being sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced, don't use set -e
    SOURCED=1
else
    # Script is being executed directly
    set -e
    SOURCED=0
fi

if [ -z "$1" ]; then
  echo "Usage: usenode <major> (e.g. 14|16|18|20|22)"
  exit 1
fi

VER="$1"
MOUNT_BASE="/opt/ext/node"
EXTRACT_BASE="/opt/ext"
DIR=""

# Try exact match directory first (in mount or already extracted)
CAND_MOUNT="$MOUNT_BASE/node${VER}"
CAND_EXTRACT="$EXTRACT_BASE/node${VER}"
if [ -d "$CAND_MOUNT" ] && [ -x "$CAND_MOUNT/bin/node" ]; then
  DIR="$CAND_MOUNT"
elif [ -d "$CAND_EXTRACT" ] && [ -x "$CAND_EXTRACT/bin/node" ]; then
  DIR="$CAND_EXTRACT"
else
  # Try exact match tar.gz
  TAR="$MOUNT_BASE/node${VER}.tar.gz"
  if [ -f "$TAR" ]; then
    mkdir -p "$CAND_EXTRACT"
    tar -xzf "$TAR" -C "$CAND_EXTRACT" --strip-components=1
    DIR="$CAND_EXTRACT"
  else
    # Try pattern match: node-vVER*.tar.gz or nodeVER*.tar.gz
    for TAR in "$MOUNT_BASE"/node-v${VER}*.tar.gz "$MOUNT_BASE"/node${VER}*.tar.gz "$MOUNT_BASE"/*node*v${VER}*.tar.gz; do
      if [ -f "$TAR" ]; then
        mkdir -p "$CAND_EXTRACT"
        tar -xzf "$TAR" -C "$CAND_EXTRACT" --strip-components=1
        DIR="$CAND_EXTRACT"
        break
      fi
    done
  fi
fi

if [ -z "$DIR" ] || [ ! -x "$DIR/bin/node" ]; then
  echo "Node $VER not found. Please mount node${VER} dir or node-v${VER}*.tar.gz under $MOUNT_BASE"
  [ "$SOURCED" = "0" ] && exit 1 || return 1
fi

export PATH="$DIR/bin:$PATH"
echo "✅ Node.js switched to $VER at $DIR"
node -v
