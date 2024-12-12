#!/usr/bin/env bash

set -eu -o pipefail

function printError() {
	echo "$@"
	exit 1
}

if [ "$#" -ne 2 ]; then
	name="$(basename "$0")"
	printError "Usage: $name <user> <newowner>"
fi

user=$1
newowner=$2

which jq >/dev/null || printError "please install jq"
which gh >/dev/null || printError "please install GitHub CLI"

gh auth status >/dev/null || printError "Please configure GitHub CLI with: gh auth login"

gh repo list --fork --limit 1000 --json name,parent "$user" | jq -r '.[] | [.name] | @tsv' | while read -r repo; do
	if [ -z "$repo" ]; then
		printError "no name found for the repository"
	fi

	echo "$repo would be moved to $newowner with the same repo name"
	echo "gh api repos/$user/$repo/transfer -f new_owner=$newowner"
done
