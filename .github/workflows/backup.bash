#!/bin/bash

  # ==== Versions ====
AZ_CLI_VERSION="2.45.0"

# ==== General settings  ====
GH_API="api.github.com"
USR_API_URL="https://${GH_API}/user"
USR_REPO_API_URL="https://$GH_API/user/repos?per_page=100"
ORG_REPO_API_URL="https://$GH_API/ORG/repos?per_page=100"
GH_WORKSPACE="/github/workspace"
EXTRA_REPOS=""

# ==== Secrets ====

# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
# see https://github.com/settings/personal-access-tokens
GHA_PAT_SYN=""

# ip addr show eth0 | grep inet
# ifconfig -a
# hostname -I
# curl ifconfig.me
# host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address"
# myip=$(curl icanhazip.com) or curl ifconfig.me or $(curl whatismyip.akamai.com)
# myip=$(dig +short myip.opendns.com @resolver1.opendns.com)      
LOCAL_IP=$(hostname -I | awk '{print $1}')

GH_USR=$(curl $USR_API_URL -H "Authorization: Bearer ${GHA_PAT_SYN}" -H "Accept: application/vnd.github.v3+json" | jq -r '.login')
GH_USR_ID=$(curl $USR_API_URL -H "Authorization: Bearer ${GHA_PAT_SYN}" -H "Accept: application/vnd.github.v3+json" | jq -r '.id')

echo "LOCAL_IP:" $LOCAL_IP
echo "GH_API:" $GH_API
echo "USR_API_URL:" $USR_API_URL
echo "GH_USR:" $GH_USR
echo "GH_USR_ID:" $GH_USR_ID 
echo "USR_REPO_API_URL:" $USR_REPO_API_URL
echo "ORG_REPO_API_URL:" $ORG_REPO_API_URL
echo "GH_WORKSPACE:" $GH_WORKSPACE
echo "AZ_CLI_VERSION:" $AZ_CLI_VERSION


backup_dir=$(date +"%F") # "%yyyy%m%d"
mkdir $backup_dir
echo "created BackUp folder " $backup_dir
cd $backup_dir

# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user


# https://docs.github.com/en/rest/orgs/orgs?apiVersion=2022-11-28#list-organizations
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-a-user
# https://docs.github.com/en/rest/guides/using-pagination-in-the-rest-api?apiVersion=2022-11-28
curl --include --request GET  ${USR_REPO_API_URL} \
    -H "Authorization: Bearer ${GHA_PAT_SYN}" -H "Accept: application/vnd.github.v3+json" -H "X-GitHub-Api-Version: 2022-11-28" \
    | grep -i "link"

page=1
repos=()
while : ; do
    response=$(curl -H "Authorization: Bearer ${GHA_PAT_SYN}" -H "Accept: application/vnd.github.v3+json" -H "X-GitHub-Api-Version: 2022-11-28" "${USR_REPO_API_URL}&page=${page}")
    repo_names=$(echo "$response" | jq -r '.[].name')
    if [ -z "$repo_names" ]; then
        break
    fi
    repos+=($repo_names)
    ((page++))
done

echo "There are ${#repos[@]} repos to BackUp"

echo "Verifying repos:"
echo ""
for index in ${!repos[@]}
    do
        echo $((index+1))/${#repos[@]} = "${repos[index]}"
        git clone git@github.com:$GH_USR/"${repos[index]}"
    done

echo ""