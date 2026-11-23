#!/bin/sh
# S.H.I.E.L.D installer: install, update or remove shield in a project.
#
# POSIX sh. Run it from a local clone of the shield repository:
#   ./install.sh --project /path/to/project
#
# Safety rules this script keeps:
#   - It only touches files listed in its manifest, plus clearly marked sections
#     of AGENTS.md, CLAUDE.md and .gitignore.
#   - It never overwrites a file it didn't install, or one you've edited, unless
#     you pass --force; originals are then backed up under .shield/backups/.
#   - It never overwrites .memory/ or .skills/local.md.
#   - Running it twice in a row changes nothing the second time.

set -eu

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
VERSION=$(cat "$SRC_DIR/VERSION" 2>/dev/null || printf 'unknown')
MANIFEST=.agents/shield.manifest
SEED_FILES='.skills/local.md .memory/project.md .memory/commands.md .memory/decisions.md .memory/pitfalls.md'
MD_START='<!-- shield:start'
MD_END='<!-- shield:end'
GI_START='# shield:start'
GI_END='# shield:end'

MODE=install
TARGET=''
DRY_RUN=0
FORCE=0
STAMP=$(date +%Y%m%d-%H%M%S)
CHANGES=0
KEPT_EDITS=0

usage() {
  cat <<EOF
S.H.I.E.L.D installer $VERSION

Usage:
  install.sh --project <path> [options]
  install.sh --here [options]

Modes (default: install):
  --update      Update an existing installation. Files you've edited are kept,
                and the new version is written beside them as <file>.shield-new.
  --uninstall   Remove shield's files and marked sections. Keeps .memory/,
                .skills/local.md and .shield/ (run history).

Options:
  --dry-run     Show what would change, without changing anything.
  --force       Replace files that clash with shield's, or that you've edited.
                Originals are backed up under .shield/backups/<timestamp>/.
  -h, --help    Show this help.
  --version     Show the shield version.
EOF
}

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

set_mode() {
  [ "$MODE" = install ] || die "choose only one of --update and --uninstall"
  MODE=$1
}

while [ $# -gt 0 ]; do
  case $1 in
    --project) [ $# -ge 2 ] || die "--project needs a path"; TARGET=$2; shift 2 ;;
    --project=*) TARGET=${1#--project=}; shift ;;
    --here) TARGET=$(pwd); shift ;;
    --update) set_mode update; shift ;;
    --uninstall) set_mode uninstall; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) say "$VERSION"; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
done

[ -n "$TARGET" ] || { usage >&2; die "choose a target with --project <path> or --here"; }
[ -d "$TARGET" ] || die "target is not a directory: $TARGET"
TARGET=$(CDPATH='' cd -- "$TARGET" && pwd)
[ "$TARGET" != "$SRC_DIR" ] || die "refusing to install shield into its own source folder"
[ -f "$SRC_DIR/.agents/dispatcher.md" ] || die "shield's files weren't found next to install.sh ($SRC_DIR)"

if command -v sha256sum >/dev/null 2>&1; then
  hash_file() { sha256sum "$1" | cut -d ' ' -f 1; }
elif command -v shasum >/dev/null 2>&1; then
  hash_file() { shasum -a 256 "$1" | cut -d ' ' -f 1; }
else
  die "sha256sum or shasum is required"
fi

TMP=$(mktemp -d "${TMPDIR:-/tmp}/shield.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
trap 'exit 130' INT TERM

# ---------------------------------------------------------------- reporting

report() { printf '  %-9s %s\n' "$1" "$2"; CHANGES=$((CHANGES + 1)); }
notice() { printf '  %-9s %s\n' "$1" "$2"; }

# ---------------------------------------------------------------- file actions
# Every change goes through these, so --dry-run is honoured everywhere.

copy_in() { # <source path> [destination path], both relative
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  mkdir -p "$(dirname "$TARGET/${2:-$1}")"
  cp "$SRC_DIR/$1" "$TARGET/${2:-$1}"
}

backup() { # <path>
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  mkdir -p "$(dirname "$TARGET/.shield/backups/$STAMP/$1")"
  cp -p "$TARGET/$1" "$TARGET/.shield/backups/$STAMP/$1"
}

prune_dirs() { # <path>: remove parent folders that are now empty
  d=$(dirname "$1")
  while [ "$d" != . ]; do
    rmdir "$TARGET/$d" 2>/dev/null || break
    d=$(dirname "$d")
  done
}

remove_file() { # <path>
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  rm -f "$TARGET/$1"
  prune_dirs "$1"
}

write_over() { # <temp file> <path>: keeps the target's permissions
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  cat "$1" > "$TARGET/$2"
}

# ---------------------------------------------------------------- manifest

list_managed() {
  (
    cd "$SRC_DIR"
    find .agents -type f -name '*.md'
    printf '%s\n' .skills/principles.md .skills/registry.md .memory/README.md
    find .claude/agents -type f -name 'shield-*.md'
    find .claude/skills -type f -path '.claude/skills/shield*' ! -name '.DS_Store'
  ) | sed 's|^\./||' | LC_ALL=C sort
}

recorded_hash() { # <path>: hash recorded at the last install or update
  if [ -f "$TMP/old_manifest" ]; then
    awk -v p="$1" '!/^#/ && $2 == p { print $1; exit }' "$TMP/old_manifest"
  fi
}

installed_version() {
  sed -n '1s/^# shield //p' "$TARGET/$MANIFEST"
}

write_manifest() {
  {
    printf '# shield %s\n' "$VERSION"
    printf '# Checksums of the shield files installed here, used by install.sh --update and --uninstall. Do not edit.\n'
    cat "$TMP/new_manifest"
  } > "$TMP/manifest_out"
  if [ -f "$TARGET/$MANIFEST" ] && cmp -s "$TMP/manifest_out" "$TARGET/$MANIFEST"; then
    return 0
  fi
  if [ "$DRY_RUN" != 1 ]; then
    mkdir -p "$(dirname "$TARGET/$MANIFEST")"
    cp "$TMP/manifest_out" "$TARGET/$MANIFEST"
  fi
  report written "$MANIFEST"
}

# ---------------------------------------------------------------- managed files

install_managed() {
  conflicts=''
  while IFS= read -r f; do
    if [ -e "$TARGET/$f" ] && ! cmp -s "$SRC_DIR/$f" "$TARGET/$f"; then
      conflicts="$conflicts  $f
"
    fi
  done < "$TMP/managed"
  if [ -n "$conflicts" ] && [ "$FORCE" != 1 ]; then
    printf 'These files already exist and were not installed by shield:\n%s' "$conflicts" >&2
    die "nothing was changed. Move them aside, or rerun with --force to back them up and replace them."
  fi

  while IFS= read -r f; do
    if [ ! -e "$TARGET/$f" ]; then
      copy_in "$f"
      report added "$f"
    elif ! cmp -s "$SRC_DIR/$f" "$TARGET/$f"; then
      backup "$f"
      copy_in "$f"
      report replaced "$f (original saved in .shield/backups/$STAMP/)"
    fi
    printf '%s  %s\n' "$(hash_file "$SRC_DIR/$f")" "$f" >> "$TMP/new_manifest"
  done < "$TMP/managed"
}

update_managed() {
  while IFS= read -r f; do
    src_h=$(hash_file "$SRC_DIR/$f")
    old_h=$(recorded_hash "$f")
    if [ ! -e "$TARGET/$f" ]; then
      copy_in "$f"
      if [ -n "$old_h" ]; then report restored "$f"; else report added "$f"; fi
    else
      cur_h=$(hash_file "$TARGET/$f")
      if [ "$cur_h" = "$src_h" ]; then
        :
      elif [ -n "$old_h" ] && [ "$cur_h" = "$old_h" ]; then
        copy_in "$f"
        report updated "$f"
      elif [ "$FORCE" = 1 ]; then
        backup "$f"
        copy_in "$f"
        report replaced "$f (your version saved in .shield/backups/$STAMP/)"
      elif [ -n "$old_h" ] && [ "$src_h" = "$old_h" ]; then
        : # edited locally, and shield has nothing new for it
      else
        copy_in "$f" "$f.shield-new"
        report kept "$f (you edited it; new version in $f.shield-new)"
        KEPT_EDITS=1
      fi
    fi
    printf '%s  %s\n' "$src_h" "$f" >> "$TMP/new_manifest"
  done < "$TMP/managed"

  # Files shield no longer ships
  awk '!/^#/ && NF == 2 { print $2 }' "$TMP/old_manifest" > "$TMP/old_paths"
  while IFS= read -r f; do
    if grep -qxF -- "$f" "$TMP/managed"; then continue; fi
    if [ ! -e "$TARGET/$f" ]; then continue; fi
    if [ "$(hash_file "$TARGET/$f")" = "$(recorded_hash "$f")" ]; then
      remove_file "$f"
      report removed "$f (no longer part of shield)"
    else
      notice kept "$f (you edited it; no longer part of shield, so delete it when ready)"
    fi
  done < "$TMP/old_paths"
}

uninstall_managed() {
  awk '!/^#/ && NF == 2 { print $2 }' "$TMP/old_manifest" > "$TMP/old_paths"
  while IFS= read -r f; do
    if [ -e "$TARGET/$f.shield-new" ]; then
      remove_file "$f.shield-new"
      report removed "$f.shield-new"
    fi
    if [ ! -e "$TARGET/$f" ]; then continue; fi
    if [ "$(hash_file "$TARGET/$f")" = "$(recorded_hash "$f")" ]; then
      remove_file "$f"
      report removed "$f"
    elif [ "$FORCE" = 1 ]; then
      backup "$f"
      remove_file "$f"
      report removed "$f (your version saved in .shield/backups/$STAMP/)"
    else
      notice kept "$f (you edited it; delete it yourself, or rerun with --force)"
    fi
  done < "$TMP/old_paths"
  remove_file "$MANIFEST"
  report removed "$MANIFEST"
}

seed_files() {
  for f in $SEED_FILES; do
    if [ ! -e "$TARGET/$f" ]; then
      copy_in "$f"
      report created "$f"
    fi
  done
}

# ---------------------------------------------------------------- marked sections

has_marker() { # <file> <line prefix>
  awk -v s="$2" 'index($0, s) == 1 { found = 1 } END { exit !found }' "$1"
}

replace_block() { # <file> <block file> <start> <end>: prints the result
  awk -v start="$3" -v end="$4" -v blockfile="$2" '
    skipping { if (index($0, end) == 1) skipping = 0; next }
    index($0, start) == 1 {
      while ((getline line < blockfile) > 0) print line
      close(blockfile)
      skipping = 1
      next
    }
    { print }
  ' "$1"
}

append_block() { # <file> <block file>: prints the result
  cat "$1"
  if [ -s "$1" ]; then
    if [ "$(tail -c 1 "$1" | wc -l | tr -d ' ')" != 1 ]; then printf '\n'; fi
    printf '\n'
  fi
  cat "$2"
}

remove_block() { # <file> <start> <end>: prints the result, minus the blank line before the block
  awk -v start="$2" -v end="$3" '
    skipping { if (index($0, end) == 1) skipping = 0; next }
    index($0, start) == 1 { skipping = 1; held = 0; next }
    held { print hold; held = 0 }
    /^[[:space:]]*$/ { hold = $0; held = 1; next }
    { print }
    END { if (held) print hold }
  ' "$1"
}

ensure_block() { # <file> <template> <start> <end>
  dest="$TARGET/$1"
  block="$SRC_DIR/templates/$2"
  if [ -L "$dest" ]; then
    notice skipped "$1 (it's a symlink; check it reaches a file with shield's section)"
    return 0
  fi
  if [ ! -e "$dest" ]; then
    if [ "$DRY_RUN" != 1 ]; then cp "$block" "$dest"; fi
    report created "$1"
    return 0
  fi
  if has_marker "$dest" "$3"; then
    if ! has_marker "$dest" "$4"; then
      warn "$1 has a shield start marker but no end marker, so it was left alone. Fix the markers and rerun."
      return 0
    fi
    replace_block "$dest" "$block" "$3" "$4" > "$TMP/block_out"
  else
    append_block "$dest" "$block" > "$TMP/block_out"
  fi
  if ! cmp -s "$TMP/block_out" "$dest"; then
    write_over "$TMP/block_out" "$1"
    report updated "$1"
  fi
}

ensure_claude_import() {
  dest="$TARGET/CLAUDE.md"
  if [ -f "$dest" ] && [ ! -L "$dest" ] && ! has_marker "$dest" "$MD_START" \
    && grep -Eq '^@(\./)?AGENTS\.md[[:space:]]*$' "$dest"; then
    return 0 # already imports AGENTS.md
  fi
  ensure_block CLAUDE.md CLAUDE.block.md "$MD_START" "$MD_END"
}

ensure_blocks() {
  ensure_block AGENTS.md AGENTS.block.md "$MD_START" "$MD_END"
  ensure_claude_import
  ensure_block .gitignore gitignore.block "$GI_START" "$GI_END"
}

remove_block_from() { # <file> <start> <end>
  dest="$TARGET/$1"
  if [ ! -f "$dest" ] || [ -L "$dest" ]; then return 0; fi
  if ! has_marker "$dest" "$2" || ! has_marker "$dest" "$3"; then return 0; fi
  remove_block "$dest" "$2" "$3" > "$TMP/block_out"
  if grep -q '[^[:space:]]' "$TMP/block_out"; then
    write_over "$TMP/block_out" "$1"
    report updated "$1 (shield section removed)"
  else
    if [ "$DRY_RUN" != 1 ]; then rm -f "$dest"; fi
    report removed "$1"
  fi
}

# ---------------------------------------------------------------- main

: > "$TMP/new_manifest"
list_managed > "$TMP/managed"

if [ "$DRY_RUN" = 1 ]; then say "Dry run: nothing will be changed."; fi

case $MODE in
  install)
    if [ -f "$TARGET/$MANIFEST" ]; then
      die "shield $(installed_version) is already installed in $TARGET. Use --update to update it."
    fi
    say "Installing shield $VERSION into $TARGET"
    if command -v git >/dev/null 2>&1 && ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
      notice note "this isn't a git repository; shield's branch and review steps work best with git"
    fi
    install_managed
    seed_files
    ensure_blocks
    write_manifest
    ;;
  update)
    [ -f "$TARGET/$MANIFEST" ] || die "shield isn't installed in $TARGET. Run without --update to install it."
    cp "$TARGET/$MANIFEST" "$TMP/old_manifest"
    say "Updating shield $(installed_version) to $VERSION in $TARGET"
    update_managed
    seed_files
    ensure_blocks
    write_manifest
    ;;
  uninstall)
    [ -f "$TARGET/$MANIFEST" ] || die "shield isn't installed in $TARGET."
    cp "$TARGET/$MANIFEST" "$TMP/old_manifest"
    say "Removing shield $(installed_version) from $TARGET"
    uninstall_managed
    remove_block_from AGENTS.md "$MD_START" "$MD_END"
    remove_block_from CLAUDE.md "$MD_START" "$MD_END"
    if [ -d "$TARGET/.shield" ]; then
      notice kept ".gitignore entry for .shield/ (the folder still holds run history)"
    else
      remove_block_from .gitignore "$GI_START" "$GI_END"
    fi
    ;;
esac

# ---------------------------------------------------------------- summary

say ""
if [ "$CHANGES" = 0 ]; then
  say "Already up to date."
  exit 0
fi
if [ "$DRY_RUN" = 1 ]; then
  say "Dry run complete: $CHANGES change(s) would be made."
  exit 0
fi

case $MODE in
  install)
    say "Installed shield $VERSION."
    say ""
    say "Next steps:"
    say "  1. Review the new files (git status) and commit them."
    say "  2. Start a new Claude Code session so it loads the shield agents and skills."
    say "  3. In an existing project, run /shield-init to fill in .memory/."
    say "  4. Try /shield <request>."
    ;;
  update)
    say "Updated shield to $VERSION."
    if [ "$KEPT_EDITS" = 1 ]; then
      say ""
      say "Some files you've edited were kept. Merge each <file>.shield-new into"
      say "its file, then delete the .shield-new copy."
    fi
    say "Start a new Claude Code session to pick up the changes."
    ;;
  uninstall)
    say "Removed shield. Kept .memory/, .skills/local.md and any .shield/ run history."
    ;;
esac
