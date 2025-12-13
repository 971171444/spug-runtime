#!/bin/bash
# Switch JDK to a mounted version. Supports directory or tar.gz under /opt/ext/jdk.
# Usage: usejdk <version>  (e.g. 8, 17, 21, 22)
# Can be sourced: source usejdk <version> or . usejdk <version>
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
  echo "Usage: usejdk <version> (e.g. 8|17|21|22)"
  exit 1
fi

VER="$1"
MOUNT_BASE="/opt/ext/jdk"
EXTRACT_BASE="/opt/ext"
DIR=""

# Try exact match directory first (in mount or already extracted)
CAND_MOUNT="$MOUNT_BASE/jdk${VER}"
CAND_EXTRACT="$EXTRACT_BASE/jdk${VER}"
if [ -d "$CAND_MOUNT" ] && [ -x "$CAND_MOUNT/bin/java" ]; then
  DIR="$CAND_MOUNT"
elif [ -d "$CAND_EXTRACT" ] && [ -x "$CAND_EXTRACT/bin/java" ]; then
  DIR="$CAND_EXTRACT"
else
  # Try exact match tar.gz
  TAR="$MOUNT_BASE/jdk${VER}.tar.gz"
  if [ -f "$TAR" ]; then
    mkdir -p "$CAND_EXTRACT"
    tar -xzf "$TAR" -C "$CAND_EXTRACT" --strip-components=1
    DIR="$CAND_EXTRACT"
  else
    # Try pattern match: OpenJDK*VER*.tar.gz or jdk*VER*.tar.gz
    for TAR in "$MOUNT_BASE"/OpenJDK*${VER}*.tar.gz "$MOUNT_BASE"/jdk*${VER}*.tar.gz "$MOUNT_BASE"/*jdk*${VER}*.tar.gz; do
      if [ -f "$TAR" ]; then
        mkdir -p "$CAND_EXTRACT"
        tar -xzf "$TAR" -C "$CAND_EXTRACT" --strip-components=1
        DIR="$CAND_EXTRACT"
        break
      fi
    done
  fi
fi

if [ -z "$DIR" ] || [ ! -x "$DIR/bin/java" ]; then
  echo "JDK $VER not found. Please mount jdk${VER} dir or JDK${VER}*.tar.gz under $MOUNT_BASE"
  [ "$SOURCED" = "0" ] && exit 1 || return 1
fi

export JAVA_HOME="$DIR"
export PATH="$JAVA_HOME/bin:$PATH"
echo "✅ JDK switched to $VER at $JAVA_HOME"
java -version
