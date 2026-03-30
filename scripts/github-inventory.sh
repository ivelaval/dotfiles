#!/usr/bin/env bash
# github-inventory.sh — Generate a JSON inventory of your GitHub repositories
# Usage: bash github-inventory.sh [OPTIONS]
#
# Requires: gh (GitHub CLI) authenticated

set -uo pipefail

# =============================================================================
# Constants
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'
OUTPUT_FILE="github-projects-inventory.json"
INCLUDE_FORKS=false
USERNAME=""

# =============================================================================
# Argument Parsing
# =============================================================================

show_help() {
  cat << 'EOF'
github-inventory.sh — Generate a JSON inventory of your GitHub repositories

Usage:
  bash github-inventory.sh [OPTIONS]

Options:
  --output <file>      Output file path (default: github-projects-inventory.json)
  --include-forks      Include forked repositories (excluded by default)
  --user <username>    GitHub username (default: authenticated user)
  --help               Show this help message

Examples:
  bash github-inventory.sh                          # Generate inventory
  bash github-inventory.sh --include-forks          # Include forks
  bash github-inventory.sh --output ~/my-repos.json # Custom output path
  bash github-inventory.sh --user ivelaval          # Specific user
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --include-forks)
      INCLUDE_FORKS=true
      shift
      ;;
    --user)
      USERNAME="$2"
      shift 2
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# =============================================================================
# Preflight checks
# =============================================================================

if ! command -v gh &>/dev/null; then
  echo -e "${RED}[ERROR]${NC} GitHub CLI (gh) is not installed. Run: brew install gh"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo -e "${RED}[ERROR]${NC} GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo -e "${RED}[ERROR]${NC} python3 is required for JSON processing"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  USERNAME=$(gh api user --jq '.login' 2>/dev/null)
  if [ -z "$USERNAME" ]; then
    echo -e "${RED}[ERROR]${NC} Could not determine GitHub username"
    exit 1
  fi
fi

echo -e "${BOLD}GitHub Repository Inventory${NC}"
echo -e "  User: ${BOLD}$USERNAME${NC}"
echo -e "  Include forks: $INCLUDE_FORKS"
echo -e "  Output: ${BOLD}$OUTPUT_FILE${NC}"
echo ""

# =============================================================================
# Fetch repositories
# =============================================================================

echo -e "  Fetching repositories from GitHub..."

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

gh repo list "$USERNAME" \
  --limit 500 \
  --json name,url,sshUrl,defaultBranchRef,description,isFork,isPrivate,primaryLanguage,createdAt,updatedAt \
  > "$TMPFILE" 2>/dev/null

if [ ! -s "$TMPFILE" ]; then
  echo -e "${RED}[ERROR]${NC} No repositories found for user $USERNAME"
  exit 1
fi

# =============================================================================
# Process and generate inventory JSON
# =============================================================================

INCLUDE_FORKS_PY=$( $INCLUDE_FORKS && echo "True" || echo "False" )

python3 - "$TMPFILE" "$OUTPUT_FILE" "$USERNAME" "$INCLUDE_FORKS_PY" << 'PYEOF'
import json
import sys
from collections import defaultdict

tmpfile, output_file, username, include_forks_str = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(tmpfile, "r") as f:
    raw = json.load(f)

include_forks = include_forks_str == "True"

# Filter forks if needed
repos = [r for r in raw if include_forks or not r.get("isFork", False)]

# Categorize by primary language
by_language = defaultdict(list)
for repo in repos:
    lang = repo.get("primaryLanguage")
    lang_name = lang["name"] if lang else "Other"
    by_language[lang_name].append(repo)

# Build groups
groups = []
for lang_name in sorted(by_language.keys()):
    lang_repos = by_language[lang_name]
    projects = []
    for r in sorted(lang_repos, key=lambda x: x["name"].lower()):
        project = {
            "name": r["name"],
            "description": r.get("description") or "",
            "url": r["sshUrl"],
            "http_url": r["url"],
            "default_branch": r["defaultBranchRef"]["name"] if r.get("defaultBranchRef") else "main",
            "is_private": r.get("isPrivate", False),
            "is_fork": r.get("isFork", False),
            "created_at": r.get("createdAt", ""),
            "updated_at": r.get("updatedAt", "")
        }
        projects.append(project)
    groups.append({
        "name": lang_name,
        "projects": projects
    })

inventory = {
    "source": "github",
    "owner": username,
    "total_repos": len(repos),
    "total_own": len([r for r in repos if not r.get("isFork", False)]),
    "total_forks": len([r for r in repos if r.get("isFork", False)]),
    "groups": groups
}

output = json.dumps(inventory, indent=2, ensure_ascii=False)

with open(output_file, "w") as f:
    f.write(output + "\n")

print(output[:200] + "...")
print()

# Print summary
print(f"  Total repos: {inventory['total_repos']}")
print(f"  Own repos: {inventory['total_own']}")
print(f"  Forks: {inventory['total_forks']}")
print(f"  Languages: {len(groups)}")
print()
for g in groups:
    print(f"    {g['name']}: {len(g['projects'])} repos")

PYEOF

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}[OK]${NC} Inventory saved to ${BOLD}$OUTPUT_FILE${NC}"
else
  echo -e "${RED}[ERROR]${NC} Failed to generate inventory"
  exit 1
fi
