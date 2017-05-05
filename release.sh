#!/usr/bin/env bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: release.sh <elastic_search_version> <github_access_token>"
    exit 1
fi
ELASTIC_VERSION=$1
ACCESS_TOKEN=$2

echo "Building with the latest Elasticsearch $1"
mvn -Delasticsearch.version=$1 clean verify

echo "Build successful, making a nexus release ..."
mvn versions:update-properties -DincludeProperties=elasticsearch.version -DgenerateBackupPoms=false
mvn versions:set -DnewVersion=${ELASTIC_VERSION}.0-SNAPSHOT -DgenerateBackupPoms=false
git commit -a -m "Auto-update ElasticSearch to $ELASTIC_VERSION"
echo mvn --batch-mode release:prepare release:perform

echo "Releasing to github.com ..."
BODY="{\"tag_name\": \"${ELASTIC_VERSION}.0\", \"name\": \"${ELASTIC_VERSION}.0\"}"
REL_ID=$(curl -sS -H "Content-Type: application/json" \
    -d "$BODY" \
    https://api.github.com/repos/guruxu/testRepo/releases?access_token=${ACCESS_TOKEN} \
    | jq -r .id)
echo curl -sS -H "Content-Type: text/plain" \
    --data-binary @README.md \
     https://uploads.github.com/repos/guruxu/testRepo/releases/${REL_ID}/assets?name=rosette-elasticsearch-plugin-${ELASTIC_VERSION}.0.txt&access_token=${ACCESS_TOKEN}

echo "Push changes to github ..."
git push --set-upstream origin master
