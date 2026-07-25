#!/usr/bin/env bash
#
# update-libs.sh - refresh the libraries in libs/ with the same tool CI uses.
#
# Runs BigWigsMods/packager (release.sh) locally in "externals only" mode:
# no TOC keyword processing, no localization, no zip, no upload. It just checks
# out every `externals:` entry from pkgmeta.yaml and copies the result back into
# the addon folder so you can review and commit the update.
#
# Usage:
#   tools/update-libs.sh [addon-dir]      # defaults to this script's addon
#
# Environment:
#   PACKAGER_REF   packager ref to run (default: v2, matching .github/workflows)
#   SVN_VERSION    portable Subversion to bootstrap on Windows (default: 1.14.5)
#   REFRESH_TOOLS  set to 1 to re-download release.sh
#
# Requirements: bash 4.3+, git, curl, unzip. On Windows (Git Bash) a portable
# Subversion is downloaded automatically if `svn` is not on PATH; elsewhere
# install svn yourself (needed for the repos.curseforge.com trunk externals).

set -euo pipefail

PACKAGER_REF="${PACKAGER_REF:-v2}"
SVN_VERSION="${SVN_VERSION:-1.14.5}"
REFRESH_TOOLS="${REFRESH_TOOLS:-}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mwarning: %s\033[0m\n' "$*" >&2; }
die() { printf '\033[1;31merror: %s\033[0m\n' "$*" >&2; exit 1; }

# --- locate the addon ------------------------------------------------------

topdir="${1:-$(dirname "$script_dir")}"
[[ -d $topdir ]] || die "no such directory: $topdir"
topdir="$(cd "$topdir" && pwd)"

pkgmeta=
for candidate in "$topdir/.pkgmeta" "$topdir/pkgmeta.yaml"; do
	[[ -f $candidate ]] && { pkgmeta="$candidate"; break; }
done
[[ -n $pkgmeta ]] || die "no .pkgmeta or pkgmeta.yaml in $topdir"
grep -q '^externals:' "$pkgmeta" || die "$pkgmeta has no externals: section"

# --- tool cache ------------------------------------------------------------

if [[ -n ${PACKAGER_CACHE:-} ]]; then
	cache="$PACKAGER_CACHE"
elif [[ -n ${LOCALAPPDATA:-} ]] && command -v cygpath &>/dev/null; then
	cache="$(cygpath -u "$LOCALAPPDATA")/wow-packager"
else
	cache="${XDG_CACHE_HOME:-$HOME/.cache}/wow-packager"
fi
mkdir -p "$cache"

for tool in git curl unzip; do
	command -v "$tool" &>/dev/null || die "$tool is required but not on PATH"
done

# release.sh needs svn for the repos.curseforge.com/wow/*/trunk externals.
if ! command -v svn &>/dev/null; then
	case "$(uname -s)" in
		MINGW* | MSYS* | CYGWIN*)
			svn_dir="$cache/svn-$SVN_VERSION"
			if [[ ! -x $svn_dir/bin/svn.exe ]]; then
				info "Bootstrapping portable Subversion $SVN_VERSION"
				rm -rf "$svn_dir" "$svn_dir.tmp"
				mkdir -p "$svn_dir.tmp"
				curl -fsSL -o "$svn_dir.tmp/svn.zip" \
					"https://www.visualsvn.com/files/Apache-Subversion-$SVN_VERSION.zip" ||
					die "failed to download Apache Subversion $SVN_VERSION"
				unzip -q "$svn_dir.tmp/svn.zip" -d "$svn_dir.tmp"
				rm -f "$svn_dir.tmp/svn.zip"
				[[ -x $svn_dir.tmp/bin/svn.exe ]] || die "unexpected Subversion archive layout"
				mv "$svn_dir.tmp" "$svn_dir"
			fi
			PATH="$svn_dir/bin:$PATH"
			;;
		*)
			die "svn is required (install subversion via your package manager)"
			;;
	esac
fi

# --- packager --------------------------------------------------------------

release_sh="$cache/release-$PACKAGER_REF.sh"
if [[ ! -f $release_sh || -n $REFRESH_TOOLS ]]; then
	info "Downloading BigWigsMods/packager@$PACKAGER_REF"
	curl -fsSL -o "$release_sh" \
		"https://raw.githubusercontent.com/BigWigsMods/packager/$PACKAGER_REF/release.sh" ||
		die "failed to download release.sh for ref '$PACKAGER_REF'"
fi

# Keep the staging area out of the addon folder so nothing untracked shows up.
releasedir="$cache/staging/$(basename "$topdir")"
rm -rf "$releasedir"
mkdir -p "$releasedir"

log="$releasedir.log"
info "Fetching externals for $(basename "$topdir")"

# -c skip copying the addon, -d skip upload, -l skip localization, -z skip zip.
set +o pipefail
set +e
bash "$release_sh" -c -d -l -z -t "$topdir" -r "$releasedir" -m "$pkgmeta" 2>&1 | tee "$log"
packager_status=${PIPESTATUS[0]}
set -e
set -o pipefail

pkgdir="$(find "$releasedir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[[ -n $pkgdir && -d $pkgdir ]] || die "packager produced no package directory (see $log)"

mapfile -t externals < <(sed -n 's/^Fetching external: //p' "$log")
[[ ${#externals[@]} -gt 0 ]] || die "packager fetched no externals (see $log)"

# --- copy the fetched libraries back into the checkout ---------------------

echo
info "Updating $(basename "$topdir")"
updated=0
failed=()
for external in "${externals[@]}"; do
	src="$pkgdir/$external"
	dest="$topdir/$external"

	# An external that failed to check out must not wipe the working copy.
	if [[ ! -d $src ]] || [[ -z "$(find "$src" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
		failed+=("$external")
		printf '    \033[1;31mfailed\033[0m   %s\n' "$external"
		continue
	fi

	if [[ -d $dest ]] && diff -qr "$src" "$dest" &>/dev/null; then
		printf '    up to date  %s\n' "$external"
		continue
	fi

	rm -rf "$dest"
	mkdir -p "$(dirname "$dest")"
	cp -a "$src" "$dest"
	printf '    \033[1;32mupdated\033[0m  %s\n' "$external"
	updated=$((updated + 1))
done

rm -rf "$releasedir"

echo
info "$updated of ${#externals[@]} externals changed"
if [[ ${#failed[@]} -gt 0 ]]; then
	warn "${#failed[@]} external(s) failed to check out and were left untouched: ${failed[*]}"
	warn "full packager output: $log"
	exit 1
fi
[[ $packager_status -eq 0 ]] || warn "release.sh exited with status $packager_status (see $log)"
echo "Review the changes with: git -C \"$topdir\" status"
