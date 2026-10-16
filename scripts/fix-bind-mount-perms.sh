#!/usr/bin/env bash
# Keep the gateways' bind-mounted folders writable after git changes them.
#
# On Linux/WSL the gateways run as uid 2003 with the student's group added
# (docker-compose.yaml: user "2003:0" + group_add LAB_GID), so they can only
# write files and folders that are group-writable. Each lab's setup.sh makes
# them so once, but folders git creates later (a pull or branch switch that
# brings in a new project or view) arrive 0755 and the Designer save fails
# with "PushException: I/O error during prepare: .../view.json.tmp".
#
# Run by the post-checkout, post-merge and post-rewrite dispatchers in
# scripts/git-hooks, and safe to run by hand from anywhere in the clone.
# Inert on macOS: Docker Desktop virtualises bind-mount ownership.
set -uo pipefail

[ "$(uname -s)" = "Linux" ] || exit 0

top="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"

for lab_dir in "$top"/labs/*/; do
    for d in projects services/config gateways third-party-modules; do
        [ -d "$lab_dir$d" ] || continue
        # Files the gateway wrote (uid 2003) are already group-writable and
        # cannot be chmod-ed by the student, so errors are expected noise.
        chmod -R g+w "$lab_dir$d" 2>/dev/null || true
        find "$lab_dir$d" -type d ! -perm -2000 -exec chmod g+s {} + 2>/dev/null || true
    done
    [ -f "${lab_dir}services/modules.json" ] && chmod g+w "${lab_dir}services/modules.json" 2>/dev/null
done
exit 0
