#!/usr/bin/env bash
# zoe-launch.sh — Zoe project launcher for Claude Code
#
# Reads PROJECTS.md for registered projects, manages git worktrees,
# deploys CLAUDE.md + STATE files, and launches Claude Code with
# an automatic "sync up" prompt so Zoe greets you immediately.
#
# Usage: bash ~/zoe/zoe-launch.sh

ZOE_ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECTS_FILE="$ZOE_ROOT/PROJECTS.md"
PROJECTS_DIR="${ZOE_PROJECTS_DIR:-$HOME/projects}"

if [[ ! -f "$PROJECTS_FILE" ]]; then
  echo "ERROR: $PROJECTS_FILE not found."
  echo "Copy PROJECTS.template.md to PROJECTS.md and register your projects."
  exit 1
fi

# --- Parse PROJECTS.md ---
declare -a KEYS NAMES SOURCES WORKTREES STARTUPS

while IFS='|' read -r _ key name source worktree startup _; do
  key=$(echo "$key" | xargs)
  [[ -z "$key" || "$key" == "key" || "$key" =~ ^[-]+ ]] && continue
  KEYS+=("$key")
  NAMES+=("$(echo "$name" | xargs)")
  SOURCES+=("$(echo "$source" | xargs)")
  WORKTREES+=("$(echo "$worktree" | xargs | sed "s|~|$HOME|g")")
  STARTUPS+=("$(echo "$startup" | xargs)")
done < "$PROJECTS_FILE"

# --- Get active worktrees from git ---
ACTIVE_WORKTREES=$(git -C "$ZOE_ROOT" worktree list 2>/dev/null | awk '{print $1}')

# --- Find unregistered projects in PROJECTS_DIR ---
declare -a UNREGISTERED
if [[ -d "$PROJECTS_DIR" ]]; then
  for dir in "$PROJECTS_DIR"/*/; do
    [[ ! -d "$dir" ]] && continue
    dname=$(basename "$dir")
    registered=false
    for src in "${SOURCES[@]}"; do
      if [[ "$src" == "$PROJECTS_DIR/$dname" ]]; then
        registered=true
        break
      fi
    done
    $registered || UNREGISTERED+=("$dname")
  done
fi

# --- Display menu ---
echo ""
echo "  Zoe Project Launcher"
echo "  ─────────────────────────────────────────"

for i in "${!KEYS[@]}"; do
  wt="${WORKTREES[$i]}"
  if echo "$ACTIVE_WORKTREES" | grep -qF "$wt"; then
    status="[active worktree]"
  else
    status="[no worktree]    "
  fi
  printf "  %2d) %-32s %s\n" "$((i+1))" "${NAMES[$i]}" "$status"
done

echo ""

if [[ ${#UNREGISTERED[@]} -gt 0 ]]; then
  echo "  ── Unregistered projects in $PROJECTS_DIR ──"
  offset=${#KEYS[@]}
  for i in "${!UNREGISTERED[@]}"; do
    printf "  %2d) %-32s [not registered]\n" "$((offset+i+1))" "${UNREGISTERED[$i]}"
  done
  echo ""
fi

echo "   N) Register a brand new project"
echo "   Q) Quit"
echo ""
read -r -p "  Select: " choice

[[ "$choice" == "q" || "$choice" == "Q" ]] && exit 0

# --- Write CLAUDE.md for a worktree ---
write_claude_md() {
  local worktree="$1" key="$2" name="$3" source="$4"
  cat > "$worktree/CLAUDE.md" << EOF
@$ZOE_ROOT/CLAUDE.md

Your STATE files for this session are at: $worktree/STATE/

Project: $name
Source: $source

On start, sync up: read ENVIRONMENT.md, TODO.md, MAILBOX.md, and CHANGELOG.md from the STATE directory above, orient to the $name project, and propose next actions.
EOF
}

# --- Handle new project registration ---
register_and_launch() {
  local dname="$1"
  local source_path="$2"

  echo ""
  echo "  Registering: $dname"

  local default_key
  default_key=$(echo "$dname" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-$//')
  read -r -p "  Key/slug [$default_key]: " key
  key="${key:-$default_key}"

  read -r -p "  Display name [$dname]: " display_name
  display_name="${display_name:-$dname}"

  local worktree_path="$HOME/zoe-$key"
  read -r -p "  Worktree path [$worktree_path]: " wt_input
  worktree_path="${wt_input:-$worktree_path}"

  read -r -p "  Startup command (optional, e.g. 'sudo systemctl start mongod'): " startup_cmd

  local rel_wt
  rel_wt=$(echo "$worktree_path" | sed "s|$HOME|~|g")
  printf "| %-24s | %-25s | %-44s | %-26s | %-62s |\n" \
    "$key" "$display_name" "$source_path" "$rel_wt" "$startup_cmd" >> "$PROJECTS_FILE"

  echo "  Added to PROJECTS.md."

  KEYS+=("$key")
  NAMES+=("$display_name")
  SOURCES+=("$source_path")
  WORKTREES+=("$worktree_path")
  STARTUPS+=("$startup_cmd")

  launch_project "$key" "$display_name" "$source_path" "$worktree_path" "$startup_cmd"
}

# --- Launch a project ---
launch_project() {
  local key="$1" name="$2" source="$3" worktree="$4" startup="$5"

  echo ""
  echo "  Project : $name"
  echo "  Source  : $source"
  echo "  Worktree: $worktree"

  # Run startup command if set
  if [[ -n "$startup" ]]; then
    echo ""
    echo "  Running startup: $startup"
    eval "$startup"
    if [[ $? -ne 0 ]]; then
      echo "  WARNING: startup command exited with errors. Continue anyway? [y/N]"
      read -r cont
      [[ "${cont,,}" != "y" ]] && exit 1
    fi
  fi

  # Create worktree if needed
  if ! echo "$ACTIVE_WORKTREES" | grep -qF "$worktree"; then
    echo ""
    echo "  Creating worktree (branch: $key)..."
    git -C "$ZOE_ROOT" worktree add "$worktree" -b "$key"
    if [[ $? -ne 0 ]]; then
      echo "ERROR: git worktree add failed."
      exit 1
    fi

    mkdir -p "$worktree/STATE"
    cp "$ZOE_ROOT/STATE/ENVIRONMENT.md" "$worktree/STATE/ENVIRONMENT.md"

    cat > "$worktree/STATE/CHANGELOG.md" << EOF
# Changelog

## $(date +%Y-%m-%d)
- Worktree created for $name
EOF

    cat > "$worktree/STATE/MAILBOX.md" << EOF
# Mailbox

Context for future sessions. Why things changed, what to remember, open threads.

Format: \`- YYYY-MM-DDTHH:MM:SSZ [category]: description\`
Categories: \`deploy\`, \`cleanup\`, \`fix\`, \`add\`, \`docs\`, \`state\`, \`config\`

## Active threads

## Notes
EOF

    cat > "$worktree/STATE/TODO.md" << EOF
# TODO

## Active
<!-- Current sprint. Keep this to 3-7 items max. -->
<!-- Format: - [ ] [P1/P2/P3] description -->

## Backlog

## Done (last 5)
EOF

    write_claude_md "$worktree" "$key" "$name" "$source"
    echo "  Worktree ready."
  else
    echo "  Worktree already exists — opening session."
    # Safety check: ensure CLAUDE.md exists (may be missing from older worktrees)
    if [[ ! -f "$worktree/CLAUDE.md" ]]; then
      echo "  CLAUDE.md missing — writing it now."
      write_claude_md "$worktree" "$key" "$name" "$source"
    fi
  fi

  echo ""
  echo "  Launching Claude Code..."
  echo "  ─────────────────────────────────────────"
  cd "$worktree" && exec claude "sync up"
}

# --- Route selection ---
if [[ "$choice" == "n" || "$choice" == "N" ]]; then
  read -r -p "  New project directory name (will be created in $PROJECTS_DIR): " new_name
  [[ -z "$new_name" ]] && echo "Cancelled." && exit 0
  new_source="$PROJECTS_DIR/$new_name"
  if [[ ! -d "$new_source" ]]; then
    read -r -p "  Create $new_source? [Y/n]: " confirm
    [[ "${confirm,,}" == "n" ]] && exit 0
    mkdir -p "$new_source"
    echo "  Directory created."
  fi
  register_and_launch "$new_name" "$new_source"
  exit 0
fi

# Numeric selection
if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
  echo "Invalid selection."
  exit 1
fi

total_registered=${#KEYS[@]}
total_unregistered=${#UNREGISTERED[@]}

if (( choice >= 1 && choice <= total_registered )); then
  idx=$((choice - 1))
  launch_project "${KEYS[$idx]}" "${NAMES[$idx]}" "${SOURCES[$idx]}" "${WORKTREES[$idx]}" "${STARTUPS[$idx]}"

elif (( choice > total_registered && choice <= total_registered + total_unregistered )); then
  idx=$((choice - total_registered - 1))
  dname="${UNREGISTERED[$idx]}"
  register_and_launch "$dname" "$PROJECTS_DIR/$dname"

else
  echo "Invalid selection."
  exit 1
fi
