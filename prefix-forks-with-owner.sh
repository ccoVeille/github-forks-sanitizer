#!/usr/bin/env bash

set -eu -o pipefail

function printError() {
	echo "$@"
	exit 1
}

if [ "$#" -ne 1 ]; then
	name="$(basename "$0")"
	printError "Usage: $name <user>"
fi
user=$1

which jq >/dev/null || printError "please install jq"
which gh >/dev/null || printError "please install GitHub CLI"

gh auth status >/dev/null || printError "Please configure GitHub CLI with: gh auth login"

gh repo list --fork --limit 1000 --json name,parent "$user" | jq -r '.[] | [.name, .parent.owner.login, .parent.name] | @tsv' | while read -r repo owner orepo; do
	if [ -z "$repo" ]; then
		printError "no name found for the repository"
	fi

	if [ -z "$owner" ]; then
		printError "no owner found for $repo"
	fi

	if [ -z "$orepo" ]; then
		printError "no original name found for $repo"
	fi

	# skip rename if it's already contains the repo name
	if [[ "$owner" =~ $repo ]]; then
		continue
	fi

	# skip rename if it's already contains the owner name
	if [[ "$repo" =~ $owner ]]; then
		continue
	fi

	echo "$repo is a fork of $owner/$orepo."
	newname="$owner-$orepo"
	echo "It could be renamed to $newname"

	echo "gh repo rename -R $user/$repo $newname"
done
