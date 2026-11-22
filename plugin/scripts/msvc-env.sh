# Sourced by the hooks that run a repo's verify (session-start.sh, merge-gate.sh). On Windows a
# C++ build with MSVC needs the environment vcvars64.bat sets up (INCLUDE, LIB, cl on PATH), and
# hooks inherit Claude Code's environment, which has none unless it was started from a Developer
# prompt. Without it a CMake repo's verify fails on the compiler's own headers.
#
# msvc_env: in a CMake repo (CMakeLists.txt in the current directory) on Windows with no cl on
# PATH, import what vcvars64.bat adds or changes. Silent; a no-op everywhere else and whenever
# Visual Studio can't be found. Call it in a subshell: it changes the environment.
# WORKFLOW_VCVARS names the .bat to use instead of the one vswhere finds (tests use it).

msvc_env() {
    case "$(uname -s 2>/dev/null)" in MINGW* | MSYS* | CYGWIN*) ;; *) return 0 ;; esac
    [ -f CMakeLists.txt ] || return 0
    command -v cl >/dev/null 2>&1 && return 0

    local bat=${WORKFLOW_VCVARS:-} pf86 vswhere inst
    if [ -z "$bat" ]; then
        pf86=$(printenv 'ProgramFiles(x86)' 2>/dev/null) || pf86='C:\Program Files (x86)'
        vswhere="$(cygpath -u "$pf86")/Microsoft Visual Studio/Installer/vswhere.exe"
        [ -x "$vswhere" ] || return 0
        inst=$("$vswhere" -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
            -property installationPath 2>/dev/null | tr -d '\r' | head -n 1)
        [ -n "$inst" ] || return 0
        bat="$inst\VC\Auxiliary\Build\vcvars64.bat"
    fi
    [ -f "$(cygpath -u "$bat")" ] || return 0

    # A script file, not cmd /c "...": nested quotes don't survive the trip through MSYS.
    local dir script
    dir=$(mktemp -d 2>/dev/null) || return 0
    script="$dir/env.cmd"
    printf '@echo off\r\nset > "%s"\r\ncall "%s" >nul 2>&1\r\nset > "%s"\r\n' \
        "$(cygpath -w "$dir/before")" "$bat" "$(cygpath -w "$dir/after")" > "$script"
    cmd //d //c "$(cygpath -w "$script")" >/dev/null 2>&1 </dev/null

    # Only what vcvars added or changed: everything else came from this shell, with its paths
    # already rewritten to Windows form on the way into cmd.
    local line name value
    if [ -s "$dir/after" ]; then
        while IFS= read -r line; do
            line=${line%$'\r'}
            name=${line%%=*}
            value=${line#*=}
            case "$name" in '' | *[!A-Za-z0-9_]* | [0-9]*) continue ;; esac
            if [ "$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')" = PATH ]; then
                export PATH="$(cygpath -u -p "$value")"
            else
                export "$name=$value"
            fi
        done < <(grep -vxF -f <(tr -d '\r' < "$dir/before") <(tr -d '\r' < "$dir/after"))
    fi
    rm -rf "$dir"
    return 0
}
