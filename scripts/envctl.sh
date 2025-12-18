#!/usr/bin/env bash
# Minimal toolchain selector for JDK / Maven / Node in one command.
# Designed for CI/流水线：传入版本或直接用环境变量即可完成设置。
set -euo pipefail

_pick_dir() {
    local tool="$1" ver="$2" bin="$3"
    local mount_base="/opt/ext/${tool}"
    local target="/opt/ext/${tool}-${ver}"
    local cand

    # Common candidates
    for cand in \
        "${mount_base}/${tool}${ver}" \
        "${mount_base}/${tool}-${ver}" \
        "${mount_base}/${tool}${ver//./}" \
        "/opt/ext/${tool}${ver}" \
        "/opt/ext/${tool}-${ver}" \
        "/opt/ext/${tool}${ver//./}"
    do
        if [ -d "$cand" ] && [ -x "$cand/bin/$bin" ]; then
            echo "$cand"
            return 0
        fi
    done

    # Any directory under mount containing version substring
    if [ -d "$mount_base" ]; then
        for cand in "$mount_base"/*; do
            if [ -d "$cand" ] && [[ "$cand" == *"$ver"* ]] && [ -x "$cand/bin/$bin" ]; then
                echo "$cand"
                return 0
            fi
        done
    fi

    # Fallback: extract first matching tar.gz into /opt/ext/<tool>-<ver>
    local tarfile
    tarfile=$(ls "${mount_base}"/*"${ver}"*.tar.gz 2>/dev/null | head -1 || true)
    if [ -n "${tarfile:-}" ]; then
        mkdir -p "$target"
        tar -xzf "$tarfile" -C "$target" --strip-components=1
        if [ -x "$target/bin/$bin" ]; then
            echo "$target"
            return 0
        fi
    fi

    return 1
}

_use_jdk() {
    local ver="$1"
    local dir
    if ! dir=$(_pick_dir "jdk" "$ver" "java"); then
        echo "JDK $ver not found under /opt/ext/jdk (tar.gz or dir with $ver)"
        return 1
    fi
    export JAVA_HOME="$dir"
    export PATH="$JAVA_HOME/bin:${PATH}"
    echo "✅ JDK -> $ver ($JAVA_HOME)"
    java -version
}

_use_mvn() {
    local ver="$1"
    if [ -z "${JAVA_HOME:-}" ]; then
        echo "Maven needs JAVA_HOME. Add --jdk <ver> or set JAVA_HOME first."
        return 1
    fi
    local dir
    if ! dir=$(_pick_dir "maven" "$ver" "mvn"); then
        echo "Maven $ver not found under /opt/ext/maven (tar.gz or dir with $ver)"
        return 1
    fi
    export MAVEN_HOME="$dir"
    export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:${PATH}"
    echo "✅ Maven -> $ver ($MAVEN_HOME)"
    mvn -v
}

_use_node() {
    local ver="$1"
    local dir
    if ! dir=$(_pick_dir "node" "$ver" "node"); then
        echo "Node $ver not found under /opt/ext/node (tar.gz or dir with $ver)"
        return 1
    fi
    export PATH="$dir/bin:${PATH}"
    echo "✅ Node -> $ver ($dir)"
    node -v
}

useenv() {
    local jdk="${JDK_VERSION:-}"
    local mvn="${MAVEN_VERSION:-}"
    local node="${NODE_VERSION:-}"
    local show=0
    local cmd=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --jdk) jdk="$2"; shift 2 ;;
            --maven|--mvn) mvn="$2"; shift 2 ;;
            --node) node="$2"; shift 2 ;;
            --show) show=1; shift ;;
            --)
                shift
                cmd=("$@")
                break
                ;;
            -h|--help)
                echo "Usage: useenv [--jdk <ver>] [--maven <ver>] [--node <ver>] [--show] [-- cmd...]"
                echo "Env vars as defaults: JDK_VERSION / MAVEN_VERSION / NODE_VERSION"
                echo "Tip (CI): useenv --jdk 17 --maven 3.9.11 --show -- mvn clean package -DskipTests"
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    if [ -n "$jdk" ]; then
        _use_jdk "$jdk"
    fi
    if [ -n "$mvn" ]; then
        if [ -z "${JAVA_HOME:-}" ] && [ -n "$jdk" ]; then
            _use_jdk "$jdk"
        fi
        _use_mvn "$mvn"
    fi
    if [ -n "$node" ]; then
        _use_node "$node"
    fi

    if [ "$show" -eq 1 ]; then
        echo "Current toolchain:"
        echo "  JAVA_HOME=${JAVA_HOME:-}"
        echo "  MAVEN_HOME=${MAVEN_HOME:-}"
        echo "  PATH=$PATH"
    fi

    if [ "${#cmd[@]}" -gt 0 ]; then
        exec "${cmd[@]}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    useenv "$@"
fi

