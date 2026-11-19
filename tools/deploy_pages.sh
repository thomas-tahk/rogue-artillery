#!/usr/bin/env bash
# Publish a web build to gh-pages under <branch>/ (main -> repo root).
# Usage: tools/deploy_pages.sh <branch> <build_dir>
# Env: DEPLOY_REMOTE  remote name/URL override (local tests)
#      GH_TOKEN + GITHUB_REPOSITORY  push to GitHub over https (CI)
set -euo pipefail
branch="${1:?usage: deploy_pages.sh <branch> <build_dir>}"
build_dir="$(cd "${2:?usage: deploy_pages.sh <branch> <build_dir>}" && pwd)"
[ -f "$build_dir/index.html" ] || { echo "no index.html in $build_dir"; exit 1; }

if [ -n "${DEPLOY_REMOTE:-}" ]; then
  remote="$DEPLOY_REMOTE"
elif [ -n "${GH_TOKEN:-}" ]; then
  remote="https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY:?}.git"
else
  remote="$(git remote get-url origin)"
fi
src_sha="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
folder="${branch//\//-}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Never let the token reach logs.
scrub() { if [ -n "${GH_TOKEN:-}" ]; then sed "s/${GH_TOKEN}/***/g"; else cat; fi; }
g() { git -C "$work" -c user.name="ci-deploy" -c user.email="ci-deploy@users.noreply.github.com" "$@"; }

# 0 = exists, 1 = missing (ls-remote exit 2); anything else is fatal.
remote_has_gh_pages() {
  local rc=0
  git ls-remote --exit-code -q "$remote" refs/heads/gh-pages >/dev/null 2>&1 || rc=$?
  case $rc in 0) return 0 ;; 2) return 1 ;; *) echo "ls-remote failed (exit $rc)" >&2; exit 1 ;; esac
}

copy_build() {
  if [ "$folder" = main ]; then
    # root: replace top-level files only, keep branch folders
    find "$work" -maxdepth 1 -type f ! -name .nojekyll -delete || return 1
    cp -a "$build_dir"/. "$work"/ || return 1
  else
    rm -rf "${work:?}/$folder" || return 1
    mkdir -p "$work/$folder" || return 1
    cp -a "$build_dir"/. "$work/$folder"/ || return 1
  fi
}

# errexit is off when called left of ||, so every step returns explicitly.
attempt() {
  local has_remote=0
  remote_has_gh_pages && has_remote=1
  rm -rf "$work"; mkdir -p "$work" || return 1
  git init -q "$work" || return 1
  g remote add target "$remote" || return 1
  if [ $has_remote = 1 ]; then
    g fetch -q --depth=1 target gh-pages || return 1
    g checkout -q -B gh-pages FETCH_HEAD || return 1
  else
    g checkout -q --orphan gh-pages || return 1
  fi
  copy_build || return 1
  touch "$work/.nojekyll" || return 1
  g add -A || return 1
  if g rev-parse -q --verify HEAD >/dev/null && g diff --cached --quiet; then
    echo "gh-pages already up to date"; return 0
  fi
  g commit -q -m "Deploy $branch ($src_sha)" || return 1
  g push -q target gh-pages:gh-pages || return 1
}

for i in 1 2 3 4 5; do
  if out="$(attempt 2>&1)"; then
    printf '%s\n' "$out" | scrub
    echo "deployed $branch"; exit 0
  fi
  printf '%s\n' "$out" | scrub
  echo "attempt $i failed"
  [ "$i" -lt 5 ] && sleep $((3 + RANDOM % 8))
done
echo "deploy failed after 5 attempts"; exit 1
