#!/bin/sh
# Tests for install.sh and the structure of shield's files.
#
#   sh tests/test-install.sh
#   TEST_SHELL=dash sh tests/test-install.sh    # run the installer under dash
#
# Every test project is created in a throwaway temporary folder.

set -u

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SH=${TEST_SHELL:-sh}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/shield-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
PASSED=0
FAILED=0
VERSION=$(cat "$ROOT/VERSION")

ok() { PASSED=$((PASSED + 1)); printf 'ok    %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL  %s\n' "$1"; }
check() { # <description> <command...>
  desc=$1
  shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}
not() { ! "$@"; }
section() { printf '\n== %s\n' "$1"; }

inst() { "$SH" "$ROOT/install.sh" "$@"; }
project() { mkdir -p "$WORK/$1" && printf '%s' "$WORK/$1"; }
snapshot() { # checksums of every file in a folder, for before/after comparisons
  (cd "$1" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done)
}
starts_with() { # <file> <expected prefix file>
  head -c "$(wc -c < "$2" | tr -d ' ')" "$1" | cmp -s - "$2"
}
same_snapshot() { [ "$1" = "$(snapshot "$2")" ]; }
manifest_matches() { # every file in the manifest exists and matches its checksum
  grep -v '^#' "$1/.agents/shield.manifest" | while read -r h f; do
    [ -f "$1/$f" ] || exit 1
    if command -v sha256sum >/dev/null 2>&1; then a=$(sha256sum "$1/$f" | cut -d ' ' -f 1)
    else a=$(shasum -a 256 "$1/$f" | cut -d ' ' -f 1); fi
    [ "$a" = "$h" ] || exit 1
  done
}

INSTALLED='.agents/README.md .agents/dispatcher.md .agents/handoffs.md .agents/architect.md
.agents/designer.md .agents/developer.md .agents/reviewer.md .agents/tester.md .agents/shield.manifest
.skills/principles.md .skills/registry.md .skills/local.md
.memory/README.md .memory/project.md .memory/commands.md .memory/decisions.md .memory/pitfalls.md
.claude/agents/shield-architect.md .claude/agents/shield-designer.md .claude/agents/shield-developer.md
.claude/agents/shield-reviewer.md .claude/agents/shield-tester.md
.claude/skills/shield/SKILL.md .claude/skills/shield/mechanics.md .claude/skills/shield-plan/SKILL.md
.claude/skills/shield-review/SKILL.md .claude/skills/shield-init/SKILL.md
AGENTS.md CLAUDE.md .gitignore'

# ---------------------------------------------------------------------------
section "Fresh install"
P=$(project fresh)
check "install succeeds" inst --project "$P"
for f in $INSTALLED; do check "installs $f" test -f "$P/$f"; done
check "AGENTS.md has the shield section" grep -q '^<!-- shield:start' "$P/AGENTS.md"
check "CLAUDE.md imports AGENTS.md" grep -qx '@AGENTS.md' "$P/CLAUDE.md"
check ".gitignore ignores .shield/" grep -qx '.shield/' "$P/.gitignore"
check "manifest records the version" grep -qx "# shield $VERSION" "$P/.agents/shield.manifest"
check "manifest checksums match the installed files" manifest_matches "$P"
check "doesn't copy the installer" not test -e "$P/install.sh"
check "doesn't copy templates or tests" not test -e "$P/templates"
check "doesn't copy shield's own AGENTS.md" not grep -q 'Working on shield' "$P/AGENTS.md"

section "Repeat install and update"
before=$(snapshot "$P")
check "second install without --update is refused" not inst --project "$P"
check "refused install changes nothing" same_snapshot "$before" "$P"
check "update with nothing new succeeds" inst --project "$P" --update
check "update with nothing new changes nothing" same_snapshot "$before" "$P"
out=$(inst --project "$P" --update 2>&1)
check "update reports already up to date" sh -c 'printf "%s" "$1" | grep -q "Already up to date"' _ "$out"

section "Dry run"
D=$(project dry)
check "dry-run install succeeds" inst --project "$D" --dry-run
check "dry-run install creates nothing" test -z "$(ls -A "$D")"
check "dry-run uninstall succeeds" inst --project "$P" --uninstall --dry-run
check "dry-run uninstall changes nothing" same_snapshot "$before" "$P"

section "Existing project"
E=$(project existing)
printf '# Project rules\n\nUse tabs.\n' > "$E/AGENTS.md"
printf '# Claude notes\n\nBe concise.\n' > "$E/CLAUDE.md"
printf 'node_modules/\n.env\n' > "$E/.gitignore"
mkdir -p "$E/.memory" "$E/.claude/agents" "$E/.claude/skills/other"
printf 'Real project knowledge.\n' > "$E/.memory/project.md"
printf -- '---\nname: other\ndescription: x\n---\n' > "$E/.claude/agents/other.md"
printf 'other skill\n' > "$E/.claude/skills/other/SKILL.md"
for f in AGENTS.md CLAUDE.md .gitignore .memory/project.md; do
  cp "$E/$f" "$WORK/existing-$(basename "$f").orig"
done
check "install succeeds" inst --project "$E"
check "keeps existing AGENTS.md content" starts_with "$E/AGENTS.md" "$WORK/existing-AGENTS.md.orig"
check "keeps existing CLAUDE.md content" starts_with "$E/CLAUDE.md" "$WORK/existing-CLAUDE.md.orig"
check "keeps existing .gitignore entries" starts_with "$E/.gitignore" "$WORK/existing-.gitignore.orig"
check "never overwrites .memory/project.md" cmp -s "$E/.memory/project.md" "$WORK/existing-project.md.orig"
check "creates missing memory files" test -f "$E/.memory/commands.md"
check "leaves other Claude agents alone" test -f "$E/.claude/agents/other.md"
check "adds the shield section once" test "$(grep -c '^<!-- shield:start' "$E/AGENTS.md")" = 1

section "Uninstall from an existing project"
check "uninstall succeeds" inst --project "$E" --uninstall
check "restores AGENTS.md exactly" cmp -s "$E/AGENTS.md" "$WORK/existing-AGENTS.md.orig"
check "restores CLAUDE.md exactly" cmp -s "$E/CLAUDE.md" "$WORK/existing-CLAUDE.md.orig"
check "restores .gitignore exactly" cmp -s "$E/.gitignore" "$WORK/existing-.gitignore.orig"
check "keeps .memory/" test -f "$E/.memory/project.md"
check "keeps memory files shield created" test -f "$E/.memory/pitfalls.md"
check "keeps .skills/local.md" test -f "$E/.skills/local.md"
check "removes shield agents" not test -e "$E/.claude/agents/shield-architect.md"
check "removes shield skills" not test -e "$E/.claude/skills/shield"
check "keeps other Claude agents" test -f "$E/.claude/agents/other.md"
check "keeps other Claude skills" test -f "$E/.claude/skills/other/SKILL.md"
check "removes the empty .agents/ folder" not test -e "$E/.agents"
check "can install again after uninstalling" inst --project "$E"

section "Uninstall from a fresh project"
F=$(project fresh-uninstall)
inst --project "$F" >/dev/null 2>&1
check "uninstall succeeds" inst --project "$F" --uninstall
check "removes the AGENTS.md shield created" not test -e "$F/AGENTS.md"
check "removes the CLAUDE.md shield created" not test -e "$F/CLAUDE.md"
check "removes the .gitignore shield created" not test -e "$F/.gitignore"
check "removes the empty .claude/ folder" not test -e "$F/.claude"
check "keeps .memory/" test -d "$F/.memory"

section "Uninstall keeps run history ignored"
H=$(project history)
inst --project "$H" >/dev/null 2>&1
mkdir -p "$H/.shield/runs/2026-11-16-example"
printf 'plan\n' > "$H/.shield/runs/2026-11-16-example/plan.md"
check "uninstall succeeds" inst --project "$H" --uninstall
check "keeps .shield/ run history" test -f "$H/.shield/runs/2026-11-16-example/plan.md"
check "keeps .shield/ in .gitignore" grep -qx '.shield/' "$H/.gitignore"

section "Clashing files"
C=$(project clash)
mkdir -p "$C/.agents"
printf 'not shield\n' > "$C/.agents/architect.md"
before=$(snapshot "$C")
check "install refuses to overwrite a file it didn't install" not inst --project "$C"
check "refused install changes nothing" same_snapshot "$before" "$C"
check "install with --force succeeds" inst --project "$C" --force
check "--force replaces the clashing file" cmp -s "$C/.agents/architect.md" "$ROOT/.agents/architect.md"
check "--force backs up the original" sh -c 'grep -rqx "not shield" "$1/.shield/backups"' _ "$C"

section "Updating with local edits"
S="$WORK/source-v2"
mkdir -p "$S"
cp -R "$ROOT/." "$S"
printf '0.2.0\n' > "$S/VERSION"
printf '\nChanged in 0.2.0.\n' >> "$S/.agents/developer.md"
printf '\nChanged in 0.2.0.\n' >> "$S/.agents/tester.md"
rm "$S/.agents/designer.md"
printf '# New role\n' > "$S/.agents/new-role.md"

U=$(project update)
inst --project "$U" >/dev/null 2>&1
printf '\nMy tweak.\n' >> "$U/.agents/developer.md"
printf '\nMy tweak.\n' >> "$U/.agents/reviewer.md"
cp "$U/.agents/developer.md" "$WORK/developer.edited"
cp "$U/.agents/reviewer.md" "$WORK/reviewer.edited"
check "update to 0.2.0 succeeds" "$SH" "$S/install.sh" --project "$U" --update
check "keeps a file you edited" cmp -s "$U/.agents/developer.md" "$WORK/developer.edited"
check "writes the new version beside it" cmp -s "$U/.agents/developer.md.shield-new" "$S/.agents/developer.md"
check "updates a file you didn't edit" cmp -s "$U/.agents/tester.md" "$S/.agents/tester.md"
check "leaves an edited file alone when shield didn't change it" cmp -s "$U/.agents/reviewer.md" "$WORK/reviewer.edited"
check "writes no .shield-new when shield didn't change the file" not test -e "$U/.agents/reviewer.md.shield-new"
check "removes a file shield no longer ships" not test -e "$U/.agents/designer.md"
check "adds a new file" test -f "$U/.agents/new-role.md"
check "records the new version" grep -qx '# shield 0.2.0' "$U/.agents/shield.manifest"
before=$(snapshot "$U")
"$SH" "$S/install.sh" --project "$U" --update >/dev/null 2>&1
check "repeating the update changes nothing" same_snapshot "$before" "$U"
check "update with --force succeeds" "$SH" "$S/install.sh" --project "$U" --update --force
check "--force replaces an edited file" cmp -s "$U/.agents/developer.md" "$S/.agents/developer.md"
check "--force restores an edited file shield didn't change" cmp -s "$U/.agents/reviewer.md" "$S/.agents/reviewer.md"
check "--force backs up your edits" sh -c 'find "$1/.shield/backups" -name developer.md | grep -q .' _ "$U"

section "Uninstall keeps edited files"
K=$(project kept)
inst --project "$K" >/dev/null 2>&1
printf '\nMy tweak.\n' >> "$K/.agents/developer.md"
check "uninstall succeeds" inst --project "$K" --uninstall
check "keeps an edited file" test -f "$K/.agents/developer.md"
check "removes unedited files" not test -e "$K/.agents/tester.md"

section "Marker and symlink edge cases"
L=$(project symlink)
printf '# Rules\n' > "$L/AGENTS.md"
ln -s AGENTS.md "$L/CLAUDE.md"
check "install succeeds with CLAUDE.md symlinked to AGENTS.md" inst --project "$L"
check "leaves the CLAUDE.md symlink in place" test -L "$L/CLAUDE.md"
check "AGENTS.md gets one shield section" test "$(grep -c '^<!-- shield:start' "$L/AGENTS.md")" = 1
check "AGENTS.md doesn't import itself" not grep -qx '@AGENTS.md' "$L/AGENTS.md"

I=$(project imports)
printf '@AGENTS.md\n' > "$I/CLAUDE.md"
inst --project "$I" >/dev/null 2>&1
check "leaves a CLAUDE.md that already imports AGENTS.md unchanged" test "$(cat "$I/CLAUDE.md")" = '@AGENTS.md'

B=$(project broken-marker)
inst --project "$B" >/dev/null 2>&1
grep -v '^<!-- shield:end' "$B/AGENTS.md" > "$WORK/broken-agents" && cp "$WORK/broken-agents" "$B/AGENTS.md"
check "update succeeds with a missing end marker" inst --project "$B" --update
check "leaves a file with a missing end marker untouched" cmp -s "$B/AGENTS.md" "$WORK/broken-agents"

check "refuses to install into shield's own folder" not inst --project "$ROOT"
check "refuses a missing target" not inst --project "$WORK/does-not-exist"
check "refuses --update and --uninstall together" not inst --project "$P" --update --uninstall

section "Structure"
for role in architect designer developer reviewer tester; do
  a="$ROOT/.claude/agents/shield-$role.md"
  check "shield-$role starts with frontmatter" test "$(head -n 1 "$a")" = '---'
  check "shield-$role name matches its file" grep -qx "name: shield-$role" "$a"
  check "shield-$role has a description" grep -q '^description: ' "$a"
  check "shield-$role sets a model" grep -Eq '^model: (opus|sonnet|haiku|fable|inherit)$' "$a"
  check "shield-$role can't dispatch other agents" sh -c '! grep -Eq "^tools:.*(:|,) *Agent *(,|$)" "$1"' _ "$a"
  check "shield-$role points at .agents/$role.md, which exists" sh -c 'grep -q ".agents/$2.md" "$1" && test -f "$3/.agents/$2.md"' _ "$a" "$role" "$ROOT"
done
for s in shield shield-plan shield-review shield-init; do
  check "skill $s name matches its folder" grep -qx "name: $s" "$ROOT/.claude/skills/$s/SKILL.md"
done
check "read-only roles have no edit tools" sh -c '! grep -Eq "^tools:.*(:|,) *(Edit|Write|NotebookEdit) *(,|$)" "$1/.claude/agents/shield-architect.md" "$1/.claude/agents/shield-reviewer.md"' _ "$ROOT"
check "no em dashes in shield's Markdown" sh -c '! grep -rl "—" "$1" --include="*.md" --include="*.block" --exclude-dir=.git' _ "$ROOT"

# ---------------------------------------------------------------------------
printf '\n%s passed, %s failed (installer run with: %s)\n' "$PASSED" "$FAILED" "$SH"
[ "$FAILED" = 0 ]
