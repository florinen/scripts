#!/bin/bash

org=omegnet 

prompt1() {
  echo -n "$1"
  read -r repo
}
prompt2() {
  echo -n "$1"
  read -r branch
}

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    echo "Visit https://cli.github.com/ for installation instructions."
    exit 1
fi

prompt1 "Enter the GitHub repo name: "
prompt2 "Enter the branch name: "

# Get workflow IDs with status "disabled_manually"
workflow_ids=($(gh api -X GET /repos/$org/$repo/actions/runs -q ".workflow_runs[] | select(.head_branch != \"$branch\") | \"\(.id)\""))

for workflow_id in "${workflow_ids[@]}"
do
#   echo "Listing runs for the workflow ID $workflow_id"
#   run_ids=( $(gh api repos/$org/$repo/actions/workflows/$workflow_id/runs --paginate | jq '.workflow_runs[].id') )
#   for run_id in "${run_ids[@]}"
#   do
    echo "Deleting Run ID $workflow_id"
    gh api repos/$org/$repo/actions/runs/$workflow_id -X DELETE >/dev/null
#   done
done