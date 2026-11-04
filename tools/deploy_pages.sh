#!/usr/bin/env bash
# Publish a web build to gh-pages under <branch>/ (main -> repo root).
# Usage: tools/deploy_pages.sh <branch> <build_dir>
# Env: DEPLOY_REMOTE (default: origin) - remote name or URL to push to.
set -euo pipefail
branch="${1:?usage: deploy_pages.sh <branch> <build_dir>}"
build_dir="$(cd "${2:?usage: deploy_pages.sh <branch> <build_dir>}" && pwd)"
remote="${DEPLOY_REMOTE:-origin}"
[ -f "$build_dir/index.html" ] || { echo "no index.html in $build_dir"; exit 1; }
if [ "$remote" = origin ]; then remote="$(git remote get-url origin)"; fi
src_sha="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

folder="${branch//\//-}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git_() { git -C "$work" -c user.name="ci-deploy" -c user.email="ci-deploy@users.noreply.github.com" "$@"; }

prepare() {
  rm -rf "$work"; mkdir -p "$work"
  git init -q "$work"
  git_ remote add target "$remote"
  if git_ fetch -q --depth=1 target gh-pages 2>/dev/null; then
    git_ checkout -q -B gh-pages FETCH_HEAD
  else
    git_ checkout -q --orphan gh-pages
  fi
  if [ "$folder" = main ]; then
    # root: replace top-level files only, keep branch folders
    find "$work" -maxdepth 1 -type f ! -name .nojekyll -delete
    cp -a "$build_dir"/. "$work"/
  else
    rm -rf "${work:?}/$folder"; mkdir -p "$work/$folder"
    cp -a "$build_dir"/. "$work/$folder"/
  fi
  touch "$work/.nojekyll"
  git_ add -A
}

push_once() {
  prepare
  if git_ rev-parse -q --verify HEAD >/dev/null && git_ diff --cached --quiet; then
    echo "gh-pages already up to date"; return 0
  fi
  git_ commit -q -m "Deploy $branch ($src_sha)"
  git_ push -q target gh-pages:gh-pages
}

push_once || { echo "push failed, retrying once on fresh gh-pages"; push_once; }
echo "deployed $branch"
