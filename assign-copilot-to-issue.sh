#!/usr/bin/env bash
set -euo pipefail

# Assign the GitHub user "copilot" to a GitHub Issue using the REST API.
# Docs: https://docs.github.com/en/rest/issues/assignees?apiVersion=2022-11-28#add-assignees-to-an-issue
#
# Auth:
# - Fine-grained PAT: repo permission "Issues" (write) OR "Pull requests" (write) for the target repo.
# - Classic PAT: ensure it can write issues for the target repo.
#
# IMPORTANT: Replace the placeholder token below before running.
GITHUB_TOKEN="PASTE_YOUR_PAT_HERE"

API_VERSION="2022-11-28"
ASSIGNEE="copilot-swe-agent[bot]"

# Default issue to match the request. You can also pass a different issue URL as arg 1.
ISSUE_URL_DEFAULT="https://github.com/asizikov-demos/assign-cca-to-the-issue/issues/1"
ISSUE_URL="${1:-$ISSUE_URL_DEFAULT}"

if [[ "$GITHUB_TOKEN" == "PASTE_YOUR_PAT_HERE" || -z "$GITHUB_TOKEN" ]]; then
  echo "Error: set GITHUB_TOKEN in this script (replace the placeholder)" >&2
  exit 1
fi

# Parse: https://github.com/{owner}/{repo}/issues/{number}
if [[ ! "$ISSUE_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)(/.*)?$ ]]; then
  echo "Error: unsupported issue URL format: $ISSUE_URL" >&2
  echo "Expected: https://github.com/{owner}/{repo}/issues/{issue_number}" >&2
  exit 1
fi

OWNER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"
ISSUE_NUMBER="${BASH_REMATCH[3]}"

API_URL="https://api.github.com/repos/${OWNER}/${REPO}/issues/${ISSUE_NUMBER}/assignees"

payload=$(printf '{"assignees":["%s"]}' "$ASSIGNEE")

tmpfile="$(mktemp)"
cleanup() { rm -f "$tmpfile"; }
trap cleanup EXIT

http_code=$(curl -sS -L \
  -o "$tmpfile" \
  -w "%{http_code}" \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: ${API_VERSION}" \
  "$API_URL" \
  -d "$payload")

if [[ "$http_code" == "201" ]]; then
  echo "Assigned '${ASSIGNEE}' to ${OWNER}/${REPO}#${ISSUE_NUMBER}"
  exit 0
fi

echo "Request failed (HTTP ${http_code}). Response body:" >&2
cat "$tmpfile" >&2
exit 1
