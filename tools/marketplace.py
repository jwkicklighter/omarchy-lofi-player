#!/usr/bin/env python3
"""Ask the Omarchy Plugin Marketplace to verify a release; a maintainer still approves it."""

import argparse
import json
import re
import subprocess
from urllib.parse import quote

REPOSITORY = "jwkicklighter/omarchy-lofi-player"
MARKETPLACE = "omacom/omarchy-plugin-marketplace"
PLUGIN_ID = "jwkicklighter.lofi-player"
NAME = "Lofi player"


def gh(*args, body=None):
    return subprocess.run(["gh", *args], input=body, text=True, check=True, capture_output=True).stdout.strip()


def marker(commit):
    return f"<!-- lofi-player-release:{commit} -->"


def verification_body(commit, tag):
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("A full commit SHA is required")
    if not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
        raise ValueError("Expected release tag vX.Y.Z")
    return f"""### Verification action

Verify and publish a newer upstream commit

### Plugin ID

{PLUGIN_ID}

### Repository URL

https://github.com/{REPOSITORY}

### Target commit

{commit}

### Verification acknowledgment

- [x] I understand that only the exact target commit can become a verified marketplace snapshot and that verification is not a security audit.

### Standard installation acknowledgment

- [ ] I confirm that this listed root plugin supports the standard Omarchy installation path and does not require manual setup.

{marker(commit)}

Release: https://github.com/{REPOSITORY}/releases/tag/{tag}
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    # Validate the tag before using it in API paths or an issue title.
    verification_body("0" * 40, args.tag)
    release = json.loads(gh("api", f"repos/{REPOSITORY}/releases/tags/{quote(args.tag, safe='')}"))
    if release["draft"] or release["prerelease"]:
        raise ValueError("Only published, non-prerelease releases can be submitted")
    commit = gh("api", f"repos/{REPOSITORY}/commits/{quote(args.tag, safe='')}", "--jq", ".sha")
    branch = gh("api", f"repos/{REPOSITORY}", "--jq", ".default_branch")
    head = gh("api", f"repos/{REPOSITORY}/commits/{quote(branch, safe='')}", "--jq", ".sha")
    if commit != head:
        raise ValueError(f"The marketplace verifies the current {branch} HEAD; {args.tag} is no longer it")
    body = verification_body(commit, args.tag)
    if args.dry_run:
        print(body)
        return
    # Search every request, closed ones included, so retries never open a duplicate.
    pages = json.loads(gh("api", "--paginate", "--slurp", f"repos/{MARKETPLACE}/issues?state=all&per_page=100"))
    for page in pages:
        for issue in page:
            if marker(commit) in (issue.get("body") or ""):
                print(f"Request already exists (edit it to rerun marketplace validation): {issue['html_url']}")
                return
    print(gh("issue", "create", "--repo", MARKETPLACE, "--title", f"[Verify]: {NAME} {args.tag}", "--body-file", "-", body=body))


if __name__ == "__main__":
    main()
