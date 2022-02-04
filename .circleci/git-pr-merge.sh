readonly REPO_TYPE=$( echo "${CIRCLE_REPOSITORY_URL}" | awk '{ match($0,/@github/) ? r="github" : r="bitbucket"; print r }' )

if [ ${REPO_TYPE} == github ]
then
    IFS='/'
    PULL_REQUEST_NUMBER=$(echo ${CIRCLE_PULL_REQUEST} | awk '{print $NF}')
    IFS=$' \t\n'
    URL="https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/pulls/${PULL_REQUEST_NUMBER}"
    BASE=$(curl -s -X GET -H "Accept: application/vnd.github.v3+json"  ${URL} | jq -r .base.ref)
fi

git config --global user.email "circleci-pre-merge@circleci.roar+pr${PULL_REQUEST_NUMBER}@gmail.com"
git config --global user.name "CircleCI Pre Merge PR # ${PULL_REQUEST_NUMBER}"
git merge ${BASE} --no-commit
