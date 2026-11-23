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

ROLES='architect designer developer reviewer tester product-owner product-manager'
SKILLS='shield shield-plan shield-review shield-ticket shield-init'
CORE='.agents/README.md .agents/dispatcher.md .agents/handoffs.md .agents/tickets.md .agents/models.md
.agents/templates/ticket.md .agents/templates/queue.md .agents/shield.manifest
.skills/principles.md .skills/registry.md .skills/local.md .skills/tools.md
.memory/README.md .memory/project.md .memory/product.md .memory/workflow.md .memory/commands.md
.memory/decisions.md .memory/pitfalls.md AGENTS.md .gitignore'
CLAUDE_FILES='CLAUDE.md .claude/skills/shield/mechanics.md'
CODEX_FILES='.codex/shield-mechanics.md'
CURSOR_FILES='.cursor/rules/shield-mechanics.mdc'
for r in $ROLES; do
  CORE="$CORE .agents/$r.md"
  CLAUDE_FILES="$CLAUDE_FILES .claude/agents/shield-$r.md"
  CODEX_FILES="$CODEX_FILES .codex/agents/shield-$r.toml"
  CURSOR_FILES="$CURSOR_FILES .cursor/agents/shield-$r.md"
done
SHARED_SKILLS=''
for s in $SKILLS; do
  CLAUDE_FILES="$CLAUDE_FILES .claude/skills/$s/SKILL.md"
  SHARED_SKILLS="$SHARED_SKILLS .agents/skills/$s/SKILL.md"
done
INSTALLED="$CORE $CLAUDE_FILES $CODEX_FILES $CURSOR_FILES $SHARED_SKILLS"

frontmatter() { # <file> <key>: value of a top-level frontmatter key
  awk -v k="$2" 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1 && index($0, k ": ") == 1 { print substr($0, length(k) + 3); exit }' "$1"
}
toml_value() { # <file> <key>: value of a top-level string key
  awk -v k="$2" 'index($0, k " = \"") == 1 { v = substr($0, length(k) + 5); sub(/"$/, "", v); print v; exit }' "$1"
}
body_of() { # <file>: everything after the frontmatter, without the blank line that follows it
  awk 'n >= 2 { if (!started && $0 == "") next; started = 1; print; next } $0 == "---" { n++ }' "$1"
}
toml_body() { # <file>: developer_instructions
  awk '$0 == "developer_instructions = \"\"\"" { on = 1; next } on && $0 == "\"\"\"" { exit } on { print }' "$1"
}
model_cell() { # <role> <field 3-7>: value from .agents/models.md, from the Claude Code model (3) to the Cursor model (7)
  awk -F '|' -v r="$1" -v c="$2" '{ n = $2; gsub(/^ +| +$/, "", n); n = tolower(n); gsub(/ /, "-", n) }
    n == r { v = $(c); gsub(/[ `]/, "", v); print v; exit }' "$ROOT/.agents/models.md"
}

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

check "installs every tool by default" grep -qx '# tools: claude codex cursor' "$P/.agents/shield.manifest"
check "creates the workflow settings with tickets off" grep -qx -- '- Source: none' "$P/.memory/workflow.md"
check "doesn't create .tickets/" not test -e "$P/.tickets"

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

section "Choosing tools"
T=$(project tools)
check "install for Claude Code only succeeds" inst --project "$T" --tools claude
for f in $CLAUDE_FILES; do check "Claude Code only installs $f" test -f "$T/$f"; done
check "Claude Code only installs no Codex files" not test -e "$T/.codex"
check "Claude Code only installs no Cursor files" not test -e "$T/.cursor"
check "Claude Code only installs no shared skills" not test -e "$T/.agents/skills"
check "records the chosen tools" grep -qx '# tools: claude' "$T/.agents/shield.manifest"
before=$(snapshot "$T")
inst --project "$T" --update >/dev/null 2>&1
check "update keeps the chosen tools" same_snapshot "$before" "$T"
check "switching to Codex and Cursor succeeds" inst --project "$T" --update --tools cursor,codex
for f in $CODEX_FILES $CURSOR_FILES $SHARED_SKILLS; do check "switching installs $f" test -f "$T/$f"; done
check "switching removes Claude Code files" not test -e "$T/.claude"
check "switching removes the CLAUDE.md shield created" not test -e "$T/CLAUDE.md"
check "records tools in a fixed order" grep -qx '# tools: codex cursor' "$T/.agents/shield.manifest"
before=$(snapshot "$T")
inst --project "$T" --update >/dev/null 2>&1
check "repeating the update changes nothing" same_snapshot "$before" "$T"
check "switching to Cursor only succeeds" inst --project "$T" --update --tools cursor
check "Cursor only removes Codex files" not test -e "$T/.codex"
check "Cursor only keeps the shared skills" test -f "$T/.agents/skills/shield/SKILL.md"
check "refuses an unknown tool" not inst --project "$T" --update --tools claude,vim
check "refuses an empty tool list" not inst --project "$T" --update --tools ,
O=$(project old-manifest)
inst --project "$O" --tools claude >/dev/null 2>&1
grep -v '^# tools: ' "$O/.agents/shield.manifest" > "$WORK/manifest-without-tools" && cp "$WORK/manifest-without-tools" "$O/.agents/shield.manifest"
check "update from a manifest without tools succeeds" inst --project "$O" --update
check "it then installs every tool" grep -qx '# tools: claude codex cursor' "$O/.agents/shield.manifest"

section "Role tools"
R=$(project role-tools)
inst --project "$R" >/dev/null 2>&1
check "seeds .skills/tools.md" cmp -s "$R/.skills/tools.md" "$ROOT/.skills/tools.md"
sed -e 's/^| Developer | - |/| Developer | `mcp__storybook__*`, mcp__storybook__docs-list |/' \
    -e 's/^| Reviewer | - |/| Reviewer | mcp__storybook__docs-list, Agent, Write, mcp__*, bad;name |/' \
    -e 's/^| Product Owner | - |/| Product Owner | mcp__storybook__docs-show |/' \
    "$R/.skills/tools.md" > "$WORK/tools.md" && cp "$WORK/tools.md" "$R/.skills/tools.md"
codex_before=$(snapshot "$R/.codex")
check "update with role tools succeeds" inst --project "$R" --update
tools_of() { frontmatter "$R/.claude/agents/shield-$1.md" tools; }
check "adds a whole server to the Developer" sh -c 'echo "$1" | grep -q ", mcp__storybook__\*, mcp__storybook__docs-list$"' _ "$(tools_of developer)"
check "adds an exact tool to the Product Owner" test "$(tools_of product-owner)" = 'Read, Grep, Glob, Bash, WebFetch, WebSearch, Skill, mcp__storybook__docs-show'
check "skips tools roles must not have" test "$(tools_of reviewer)" = 'Read, Grep, Glob, Bash, Skill, mcp__storybook__docs-list'
check "leaves roles without extra tools alone" cmp -s "$R/.claude/agents/shield-tester.md" "$ROOT/.claude/agents/shield-tester.md"
check "keeps the agent body unchanged" test "$(body_of "$R/.claude/agents/shield-developer.md")" = "$(body_of "$ROOT/.claude/agents/shield-developer.md")"
check "leaves Codex agents alone" same_snapshot "$codex_before" "$R/.codex"
check "never overwrites .skills/tools.md" cmp -s "$R/.skills/tools.md" "$WORK/tools.md"
check "manifest records the merged agents" manifest_matches "$R"
out=$(inst --project "$R" --update 2>&1)
check "warns about skipped tools" sh -c 'printf "%s" "$1" | grep -q "skipped Agent for reviewer"' _ "$out"
check "repeating the update reports nothing new" sh -c 'printf "%s" "$1" | grep -q "Already up to date"' _ "$out"
printf '\nMy tweak.\n' >> "$R/.claude/agents/shield-developer.md"
cp "$R/.claude/agents/shield-developer.md" "$WORK/developer-agent.edited"
sed 's/^| Developer | .*/| Developer | mcp__storybook__docs-show |/' "$R/.skills/tools.md" > "$WORK/tools2.md" && cp "$WORK/tools2.md" "$R/.skills/tools.md"
inst --project "$R" --update >/dev/null 2>&1
check "keeps an agent you edited when the table changes" cmp -s "$R/.claude/agents/shield-developer.md" "$WORK/developer-agent.edited"
check "puts the merged tools in its .shield-new" sh -c 'grep -q "^tools: .*, mcp__storybook__docs-show$" "$1"' _ "$R/.claude/agents/shield-developer.md.shield-new"
sed 's/^| Product Owner | .*/| Product Owner | - |/' "$R/.skills/tools.md" > "$WORK/tools3.md" && cp "$WORK/tools3.md" "$R/.skills/tools.md"
inst --project "$R" --update >/dev/null 2>&1
check "removes tools taken out of the table" cmp -s "$R/.claude/agents/shield-product-owner.md" "$ROOT/.claude/agents/shield-product-owner.md"
check "uninstall with role tools succeeds" inst --project "$R" --uninstall
check "uninstall removes merged agents" not test -e "$R/.claude/agents/shield-reviewer.md"
check "uninstall keeps .skills/tools.md" test -f "$R/.skills/tools.md"

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
for role in $ROLES; do
  a="$ROOT/.claude/agents/shield-$role.md"
  x="$ROOT/.codex/agents/shield-$role.toml"
  c="$ROOT/.cursor/agents/shield-$role.md"
  check "shield-$role starts with frontmatter" test "$(head -n 1 "$a")" = '---'
  check "shield-$role name matches its file" test "$(frontmatter "$a" name)" = "shield-$role"
  check "shield-$role has a description" test -n "$(frontmatter "$a" description)"
  check "shield-$role sets a Claude Code model alias" sh -c 'echo "$1" | grep -Eqx "opus|sonnet|haiku|fable|inherit"' _ "$(frontmatter "$a" model)"
  check "shield-$role can't dispatch other agents" sh -c '! grep -Eq "^tools:.*(:|,) *Agent *(,|$)" "$1"' _ "$a"
  check "shield-$role points at .agents/$role.md, which exists" sh -c 'grep -q ".agents/$2.md" "$1" && test -f "$3/.agents/$2.md"' _ "$a" "$role" "$ROOT"
  check "shield-$role has a row in models.md" test -n "$(model_cell "$role" 3)"
  check "shield-$role Claude Code model matches models.md" test "$(frontmatter "$a" model)" = "$(model_cell "$role" 3)"
  check "shield-$role Claude Code effort matches models.md" test "$(frontmatter "$a" effort)" = "$(model_cell "$role" 4 | sed 's/^-$//')"
  check "shield-$role Codex name matches its file" test "$(toml_value "$x" name)" = "shield-$role"
  check "shield-$role Codex description matches Claude Code's" test "$(toml_value "$x" description)" = "$(frontmatter "$a" description)"
  check "shield-$role Codex model matches models.md" test "$(toml_value "$x" model)" = "$(model_cell "$role" 5)"
  check "shield-$role Codex effort matches models.md" test "$(toml_value "$x" model_reasoning_effort)" = "$(model_cell "$role" 6 | sed 's/^-$//')"
  check "shield-$role Codex instructions match Claude Code's" test "$(toml_body "$x")" = "$(body_of "$a")"
  check "shield-$role Cursor name matches its file" test "$(frontmatter "$c" name)" = "shield-$role"
  check "shield-$role Cursor description matches Claude Code's" test "$(frontmatter "$c" description)" = "$(frontmatter "$a" description)"
  check "shield-$role Cursor model matches models.md" test "$(frontmatter "$c" model)" = "$(model_cell "$role" 7)"
  check "shield-$role Cursor body matches Claude Code's" test "$(body_of "$c")" = "$(body_of "$a")"
done
for role in architect designer reviewer product-owner product-manager; do
  check "shield-$role is read-only in Cursor" test "$(frontmatter "$ROOT/.cursor/agents/shield-$role.md" readonly)" = true
done
for s in $SKILLS; do
  check "skill $s name matches its folder" test "$(frontmatter "$ROOT/.claude/skills/$s/SKILL.md" name)" = "$s"
  check "shared skill $s matches the Claude Code skill" sh -c 'grep -v "^argument-hint: " "$1" | cmp -s - "$2"' _ "$ROOT/.claude/skills/$s/SKILL.md" "$ROOT/.agents/skills/$s/SKILL.md"
  check "skill $s names every tool's mechanics file" sh -c 'for m in .claude/skills/shield/mechanics.md .codex/shield-mechanics.md .cursor/rules/shield-mechanics.mdc; do grep -qF "$m" "$1" && test -f "$2/$m" || exit 1; done' _ "$ROOT/.claude/skills/$s/SKILL.md" "$ROOT"
done
check "every Claude Code agent uses an allowlist" sh -c 'for r in $2; do grep -q "^tools: " "$1/.claude/agents/shield-$r.md" && ! grep -q "^disallowedTools:" "$1/.claude/agents/shield-$r.md" || exit 1; done' _ "$ROOT" "$ROLES"
check "read-only roles have no edit tools" sh -c 'for r in architect designer reviewer tester product-owner product-manager; do ! grep -Eq "^tools:.*(:|,) *(Edit|Write|NotebookEdit) *(,|$)" "$1/.claude/agents/shield-$r.md" || exit 1; done' _ "$ROOT"
check "no em dashes in shield's files" sh -c '! grep -rl "—" "$1" --include="*.md" --include="*.mdc" --include="*.toml" --include="*.block" --exclude-dir=.git' _ "$ROOT"

# ---------------------------------------------------------------------------
printf '\n%s passed, %s failed (installer run with: %s)\n' "$PASSED" "$FAILED" "$SH"
[ "$FAILED" = 0 ]
