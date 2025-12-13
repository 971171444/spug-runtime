#!/bin/bash
# Function definitions for usejdk/usemvn/usenode
# These functions set environment variables in the current shell

usejdk() {
    if [ -z "$1" ]; then
        echo "Usage: usejdk <version> (e.g. 8|17|21|22)"
        return 1
    fi
    
    VER="$1"
    MOUNT_BASE="/opt/ext/jdk"
    EXTRACT_BASE="/opt/ext"
    DIR=""
    
    # Try exact match directory first
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
            # Try pattern match
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
        return 1
    fi
    
    export JAVA_HOME="$DIR"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "✅ JDK switched to $VER at $JAVA_HOME"
    java -version
}

usemvn() {
    if [ -z "$1" ]; then
        echo "Usage: usemvn <version> (e.g. 3.6.3|3.9.11)"
        return 1
    fi
    
    VER="$1"
    MOUNT_BASE="/opt/ext/maven"
    EXTRACT_BASE="/opt/ext"
    DIR=""
    
    # Try exact match directory first
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
            # Try pattern match
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
        return 1
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
}

usenode() {
    if [ -z "$1" ]; then
        echo "Usage: usenode <major> (e.g. 14|16|18|20|22)"
        return 1
    fi
    
    VER="$1"
    MOUNT_BASE="/opt/ext/node"
    EXTRACT_BASE="/opt/ext"
    DIR=""
    
    # Try exact match directory first
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
            # Try pattern match
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
        return 1
    fi
    
    export PATH="$DIR/bin:$PATH"
    echo "✅ Node.js switched to $VER at $DIR"
    node -v
}

