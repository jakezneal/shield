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
#   - It never overwrites .memory/, .skills/local.md, .skills/tools.md or .tickets/.
#   - Claude Code agents get the extra tools listed in .skills/tools.md; the
#     manifest records the merged file, so a table change isn't a local edit.
#   - Running it twice in a row changes nothing the second time.

set -eu

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
VERSION=$(cat "$SRC_DIR/VERSION" 2>/dev/null || printf 'unknown')
MANIFEST=.agents/shield.manifest
SEED_FILES='.skills/local.md .skills/tools.md .memory/project.md .memory/commands.md .memory/decisions.md .memory/pitfalls.md .memory/product.md .memory/workflow.md'
ALL_TOOLS='claude codex cursor'
MD_START='<!-- shield:start'
MD_END='<!-- shield:end'
GI_START='# shield:start'
GI_END='# shield:end'

MODE=install
TARGET=''
DRY_RUN=0
FORCE=0
TOOLS=''
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
                Also applies .skills/tools.md to the Claude Code agents.
  --uninstall   Remove shield's files and marked sections. Keeps .memory/,
                .skills/local.md, .skills/tools.md and .shield/ (run history).

Options:
  --tools <list> Which tools to install adapters for, comma-separated, from
                claude, codex and cursor. Default: all three on install, and
                the tools chosen last time on update.
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
    --tools) [ $# -ge 2 ] || die "--tools needs a list, such as claude,cursor"; TOOLS=$2; shift 2 ;;
    --tools=*) TOOLS=${1#--tools=}; shift ;;
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

normalise_tools() { # <comma or space separated list>: prints known tools in a fixed order
  list=$(printf '%s' "$1" | tr ',' ' ')
  [ -n "$(printf '%s' "$list" | tr -d ' ')" ] || die "--tools needs at least one of: claude, codex, cursor"
  for t in $list; do
    case $t in claude|codex|cursor) ;; *) die "unknown tool in --tools: $t (choose from claude, codex, cursor)" ;; esac
  done
  out=''
  for t in $ALL_TOOLS; do
    case " $list " in *" $t "*) out="$out $t" ;; esac
  done
  printf '%s' "${out# }"
}
if [ -n "$TOOLS" ]; then TOOLS=$(normalise_tools "$TOOLS"); fi
has_tool() { case " $TOOLS " in *" $1 "*) return 0 ;; esac; return 1; }
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
STAGE=$TMP/stage
trap 'rm -rf "$TMP"' EXIT
trap 'exit 130' INT TERM

# ---------------------------------------------------------------- reporting

report() { printf '  %-9s %s\n' "$1" "$2"; CHANGES=$((CHANGES + 1)); }
notice() { printf '  %-9s %s\n' "$1" "$2"; }

# ---------------------------------------------------------------- file actions
# Every change goes through these, so --dry-run is honoured everywhere.

copy_in() { # <source path> [destination path], both relative; copies the staged version
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  mkdir -p "$(dirname "$TARGET/${2:-$1}")"
  cp "$STAGE/$1" "$TARGET/${2:-$1}"
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
    find .agents -type f -name '*.md' ! -path '.agents/skills/*'
    printf '%s\n' .skills/principles.md .skills/registry.md .memory/README.md
    if has_tool claude; then
      find .claude/agents -type f -name 'shield-*.md'
      find .claude/skills -type f -path '.claude/skills/shield*' ! -name '.DS_Store'
    fi
    if has_tool codex; then
      find .codex/agents -type f -name 'shield-*.toml'
      printf '%s\n' .codex/shield-mechanics.md
    fi
    if has_tool cursor; then
      find .cursor/agents -type f -name 'shield-*.md'
      printf '%s\n' .cursor/rules/shield-mechanics.mdc
    fi
    if has_tool codex || has_tool cursor; then
      find .agents/skills -type f -path '.agents/skills/shield*' ! -name '.DS_Store'
    fi
  ) | sed 's|^\./||' | LC_ALL=C sort -u
}

recorded_hash() { # <path>: hash recorded at the last install or update
  if [ -f "$TMP/old_manifest" ]; then
    awk -v p="$1" '!/^#/ && $2 == p { print $1; exit }' "$TMP/old_manifest"
  fi
}

installed_version() {
  sed -n '1s/^# shield //p' "$TARGET/$MANIFEST"
}

installed_tools() { # tools recorded at the last install or update; all of them for manifests that predate --tools
  t=$(sed -n 's/^# tools: //p' "$TARGET/$MANIFEST" | head -n 1)
  printf '%s' "${t:-$ALL_TOOLS}"
}

write_manifest() {
  {
    printf '# shield %s\n' "$VERSION"
    printf '# tools: %s\n' "$TOOLS"
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

# ---------------------------------------------------------------- staging
# Every file is installed from $STAGE: shield's own copy, except that Claude Code
# agents get the project's extra tools from .skills/tools.md.

role_tools() ( # <role>: the role's valid extra tools from .skills/tools.md, comma-separated
  [ -f "$TARGET/.skills/tools.md" ] || exit 0
  cell=$(awk -F '|' -v r="$1" '/^ *[|]/ { n = $2; gsub(/^ +| +$/, "", n); n = tolower(n); gsub(/ +/, "-", n); if (n == r) { print $3; exit } }' "$TARGET/.skills/tools.md")
  set -f
  IFS=,
  out=''
  for t in $cell; do
    t=$(printf '%s' "$t" | tr -d ' `')
    case $t in
      ''|-) continue ;;
      *[!A-Za-z0-9_.*-]*) warn ".skills/tools.md: skipped '$t' for $1 (not a tool name)"; continue ;;
      mcp__?*__\*) ;;
      *\**) warn ".skills/tools.md: skipped '$t' for $1 (use mcp__<server>__* for a whole server)"; continue ;;
      Agent) warn ".skills/tools.md: skipped Agent for $1 (roles never dispatch agents)"; continue ;;
      Edit|Write|NotebookEdit)
        if [ "$1" != developer ]; then warn ".skills/tools.md: skipped $t for $1 (only the Developer edits files)"; continue; fi ;;
    esac
    out="${out:+$out, }$t"
  done
  printf '%s' "$out"
)

render_agent() { # <managed path> <output file>: adds the role's extra tools to its tools: line
  role=${1#.claude/agents/shield-}
  role=${role%.md}
  extra=$(role_tools "$role")
  awk -v extra="$extra" '
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---" { fm = 0; print; next }
    fm && extra != "" && index($0, "tools: ") == 1 {
      line = $0
      n = split(substr($0, 8), have, /, */)
      for (i = 1; i <= n; i++) seen[have[i]] = 1
      m = split(extra, add, /, /)
      for (i = 1; i <= m; i++) if (!(add[i] in seen)) { line = line ", " add[i]; seen[add[i]] = 1 }
      print line
      next
    }
    { print }' "$SRC_DIR/$1" > "$2"
}

stage_files() {
  { cat "$TMP/managed"; printf '%s\n' $SEED_FILES; } | while IFS= read -r f; do
    mkdir -p "$(dirname "$STAGE/$f")"
    case $f in
      .claude/agents/shield-*.md) render_agent "$f" "$STAGE/$f" ;;
      *) cp "$SRC_DIR/$f" "$STAGE/$f" ;;
    esac
  done
}

# ---------------------------------------------------------------- managed files

install_managed() {
  conflicts=''
  while IFS= read -r f; do
    if [ -e "$TARGET/$f" ] && ! cmp -s "$STAGE/$f" "$TARGET/$f"; then
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
    elif ! cmp -s "$STAGE/$f" "$TARGET/$f"; then
      backup "$f"
      copy_in "$f"
      report replaced "$f (original saved in .shield/backups/$STAMP/)"
    fi
    printf '%s  %s\n' "$(hash_file "$STAGE/$f")" "$f" >> "$TMP/new_manifest"
  done < "$TMP/managed"
}

update_managed() {
  while IFS= read -r f; do
    src_h=$(hash_file "$STAGE/$f")
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
      report removed "$f (no longer part of shield for these tools)"
    else
      notice kept "$f (you edited it; no longer part of shield for these tools, so delete it when ready)"
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
  if has_tool claude; then
    ensure_claude_import
  else
    remove_block_from CLAUDE.md "$MD_START" "$MD_END"
  fi
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

if [ "$DRY_RUN" = 1 ]; then say "Dry run: nothing will be changed."; fi

case $MODE in
  install)
    if [ -f "$TARGET/$MANIFEST" ]; then
      die "shield $(installed_version) is already installed in $TARGET. Use --update to update it."
    fi
    TOOLS=${TOOLS:-$ALL_TOOLS}
    list_managed > "$TMP/managed"
    say "Installing shield $VERSION into $TARGET for: $TOOLS"
    stage_files
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
    TOOLS=${TOOLS:-$(installed_tools)}
    list_managed > "$TMP/managed"
    say "Updating shield $(installed_version) to $VERSION in $TARGET for: $TOOLS"
    stage_files
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
    say "  2. Start a new session in your tool so it loads the shield agents and skills."
    if has_tool codex; then
      say "     In Codex, trust the project so it loads .codex/agents/."
    fi
    say "  3. Run /shield-init (\$shield-init in Codex) to choose tickets and product"
    say "     roles, and to fill in .memory/."
    say "  4. Try /shield <request> (\$shield <request> in Codex)."
    ;;
  update)
    say "Updated shield to $VERSION."
    if [ "$KEPT_EDITS" = 1 ]; then
      say ""
      say "Some files you've edited were kept. Merge each <file>.shield-new into"
      say "its file, then delete the .shield-new copy."
    fi
    say "Start a new session in your tool to pick up the changes."
    ;;
  uninstall)
    say "Removed shield. Kept .memory/, .skills/local.md, .skills/tools.md and any .shield/ run history."
    ;;
esac
