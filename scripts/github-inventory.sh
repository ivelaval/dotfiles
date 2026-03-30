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
ORGS=()
INCLUDE_ORGS=true

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
  --orgs <org1,org2>   Comma-separated list of GitHub orgs to include
  --include-orgs       Auto-detect and include all your GitHub organizations
  --help               Show this help message

Grouping:
  - User repos are grouped by their GitHub topics. Repos without topics go into "Uncategorized".
  - Each organization becomes its own group with all its repos inside.

  To add topics to a repo:
    gh repo edit <user>/<repo> --add-topic <topic>

Examples:
  bash github-inventory.sh                                            # User repos only
  bash github-inventory.sh --orgs vennet-developers,plata-system      # Include orgs
  bash github-inventory.sh --include-orgs                              # Auto-detect all orgs
  bash github-inventory.sh --include-forks --orgs my-org              # With forks + specific org
  bash github-inventory.sh --output ~/my-repos.json                   # Custom output path
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
    --orgs)
      IFS=',' read -ra ORGS <<< "$2"
      shift 2
      ;;
    --include-orgs)
      INCLUDE_ORGS=true
      shift
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

# Auto-detect orgs if --include-orgs flag is set
if $INCLUDE_ORGS; then
  echo -e "  Detecting organizations..."
  while IFS= read -r org; do
    ORGS+=("$org")
  done < <(gh api user/orgs --jq '.[].login' 2>/dev/null)
fi

echo -e "${BOLD}GitHub Repository Inventory${NC}"
echo -e "  User: ${BOLD}$USERNAME${NC}"
if [ ${#ORGS[@]} -gt 0 ]; then
  echo -e "  Orgs: ${BOLD}${ORGS[*]}${NC}"
fi
echo -e "  Include forks: $INCLUDE_FORKS"
echo -e "  Output: ${BOLD}$OUTPUT_FILE${NC}"
echo ""

# =============================================================================
# Fetch repositories
# =============================================================================

TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# Fetch user repos
echo -e "  Fetching repos for ${BOLD}$USERNAME${NC}..."
gh repo list "$USERNAME" \
  --limit 500 \
  --json name,url,sshUrl,defaultBranchRef,description,isFork,isPrivate,repositoryTopics \
  > "$TMPDIR_WORK/user.json" 2>/dev/null

if [ ! -s "$TMPDIR_WORK/user.json" ]; then
  echo -e "${RED}[ERROR]${NC} No repositories found for user $USERNAME"
  exit 1
fi

# Fetch org repos
for org in "${ORGS[@]}"; do
  org=$(echo "$org" | xargs) # trim whitespace
  echo -e "  Fetching repos for org ${BOLD}$org${NC}..."
  gh repo list "$org" \
    --limit 500 \
    --json name,url,sshUrl,defaultBranchRef,description,isFork,isPrivate,repositoryTopics \
    > "$TMPDIR_WORK/org_${org}.json" 2>/dev/null

  if [ ! -s "$TMPDIR_WORK/org_${org}.json" ]; then
    echo -e "${YELLOW}[WARN]${NC} No repositories found for org $org (or no access)"
  fi
done

# =============================================================================
# Process and generate inventory JSON
# =============================================================================

INCLUDE_FORKS_PY=$( $INCLUDE_FORKS && echo "True" || echo "False" )
ORGS_CSV=$(IFS=','; echo "${ORGS[*]+"${ORGS[*]}"}")

python3 - "$TMPDIR_WORK" "$OUTPUT_FILE" "$USERNAME" "$INCLUDE_FORKS_PY" "$ORGS_CSV" << 'PYEOF'
import json
import sys
import os
from collections import defaultdict

work_dir, output_file, username, include_forks_str, orgs_csv = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

include_forks = include_forks_str == "True"
orgs = [o.strip() for o in orgs_csv.split(",") if o.strip()] if orgs_csv else []

def filter_forks(repos):
    if include_forks:
        return repos
    return [r for r in repos if not r.get("isFork", False)]

def build_project(repo):
    return {
        "name": repo["name"],
        "url": repo["sshUrl"],
        "http_url": repo["url"],
        "default_branch": repo["defaultBranchRef"]["name"] if repo.get("defaultBranchRef") else "main"
    }

# ── Process user repos (grouped by topic) ──────────────────────────────────

with open(os.path.join(work_dir, "user.json"), "r") as f:
    user_repos = filter_forks(json.load(f))

by_topic = defaultdict(list)
for repo in user_repos:
    raw_topics = repo.get("repositoryTopics") or []
    topics = sorted([t["name"] for t in raw_topics if isinstance(t, dict) and "name" in t])
    group_name = topics[0].replace("-", " ").title() if topics else "Uncategorized"
    by_topic[group_name].append(repo)

groups = []
for group_name in sorted(by_topic.keys()):
    group_repos = by_topic[group_name]
    projects = [build_project(r) for r in sorted(group_repos, key=lambda x: x["name"].lower())]
    groups.append({"name": group_name, "projects": projects})

# ── Process org repos (each org is its own group) ──────────────────────────

for org in orgs:
    org_file = os.path.join(work_dir, f"org_{org}.json")
    if not os.path.exists(org_file) or os.path.getsize(org_file) == 0:
        continue
    with open(org_file, "r") as f:
        org_repos = filter_forks(json.load(f))
    if not org_repos:
        continue
    projects = [build_project(r) for r in sorted(org_repos, key=lambda x: x["name"].lower())]
    groups.append({"name": f"Org: {org}", "projects": projects})

inventory = {"groups": groups}

output = json.dumps(inventory, indent=2, ensure_ascii=False)
with open(output_file, "w") as f:
    f.write(output + "\n")

# ── Print summary ──────────────────────────────────────────────────────────

total_user = len(user_repos)
grouped = sum(1 for r in user_repos if any(t["name"] for t in (r.get("repositoryTopics") or []) if isinstance(t, dict)))

print(f"  User repos: {total_user} ({grouped} with topics, {total_user - grouped} uncategorized)")

for org in orgs:
    org_file = os.path.join(work_dir, f"org_{org}.json")
    if os.path.exists(org_file) and os.path.getsize(org_file) > 0:
        with open(org_file, "r") as f:
            org_repos = filter_forks(json.load(f))
        print(f"  Org {org}: {len(org_repos)} repos")

print(f"  Total groups: {len(groups)}")
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
