#!/bin/bash
# Switch Maven to a mounted version. Supports directory or tar.gz under /opt/ext/maven.
# Usage: usemvn <version> (e.g. 3.6.3, 3.9.11)
# Can be sourced: source usemvn <version> or . usemvn <version>
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
  echo "Usage: usemvn <version> (e.g. 3.6.3|3.9.11)"
  exit 1
fi

VER="$1"
MOUNT_BASE="/opt/ext/maven"
EXTRACT_BASE="/opt/ext"
DIR=""

# Try exact match directory first (in mount or already extracted)
CAND1_MOUNT="$MOUNT_BASE/maven-${VER}"
CAND2_MOUNT="$MOUNT_BASE/maven${VER//./}"
CAND1_EXTRACT="$EXTRACT_BASE/maven-${VER}"
CAND2_EXTRACT="$EXTRACT_BASE/maven${VER//./}"
if [ -d "$CAND1_MOUNT" ] && [ -x "$CAND1_MOUNT/bin/mvn" ]; then
  DIR="$CAND1_MOUNT"
elif [ -d "$CAND2_MOUNT" ] && [ -x "$CAND2_MOUNT/bin/mvn" ]; then
  DIR="$CAND2_MOUNT"
elif [ -d "$CAND1_EXTRACT" ] && [ -x "$CAND1_EXTRACT/bin/mvn" ]; then
  DIR="$CAND1_EXTRACT"
elif [ -d "$CAND2_EXTRACT" ] && [ -x "$CAND2_EXTRACT/bin/mvn" ]; then
  DIR="$CAND2_EXTRACT"
else
  # Try exact match tar.gz
  TAR="$MOUNT_BASE/maven-${VER}.tar.gz"
  if [ -f "$TAR" ]; then
    EXTRACTED=$(tar -tf "$TAR" | head -1 | cut -d/ -f1)
    mkdir -p "$EXTRACT_BASE"
    tar -xzf "$TAR" -C "$EXTRACT_BASE"
    if [ -d "$EXTRACT_BASE/$EXTRACTED" ]; then
      DIR="$EXTRACT_BASE/$EXTRACTED"
    fi
  else
    # Try pattern match: apache-maven-VER*.tar.gz or maven-VER*.tar.gz
    for TAR in "$MOUNT_BASE"/apache-maven-${VER}*.tar.gz "$MOUNT_BASE"/maven-${VER}*.tar.gz "$MOUNT_BASE"/*maven*${VER}*.tar.gz; do
      if [ -f "$TAR" ]; then
        EXTRACTED=$(tar -tf "$TAR" | head -1 | cut -d/ -f1)
        mkdir -p "$EXTRACT_BASE"
        tar -xzf "$TAR" -C "$EXTRACT_BASE"
        if [ -d "$EXTRACT_BASE/$EXTRACTED" ]; then
          DIR="$EXTRACT_BASE/$EXTRACTED"
          break
        fi
      fi
    done
  fi
fi

if [ -z "$DIR" ] || [ ! -x "$DIR/bin/mvn" ]; then
  echo "Maven $VER not found. Please mount dir or Maven${VER}*.tar.gz under $MOUNT_BASE"
  [ "$SOURCED" = "0" ] && exit 1 || return 1
fi

export MAVEN_HOME="$DIR"
if [ -z "$JAVA_HOME" ]; then
  echo "⚠️  Warning: JAVA_HOME not set. Please run 'usejdk <version>' first."
  echo "✅ Maven switched to $VER at $MAVEN_HOME (but mvn may not work without JAVA_HOME)"
else
  export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"
  echo "✅ Maven switched to $VER at $MAVEN_HOME"
  mvn -v
fi
