function init {

    tmp_dir=tmp
    if [ ! -d ${tmp_dir} ]
    then
        mkdir ${tmp_dir}
    fi

    if [ "${CI}" != "true" ]
    then
        # this file, when not in CI environment, needs to contain the following:
            # export CIRCLE_USER_TOKEN="your user token"
            # export CIRCLE_PROJECT_USERNAME="your project user name"
            # export CIRCLE_PROJECT_REPONAME="your project repo name"
        source ${tmp_dir}/init
    fi

    rand=$(openssl rand -hex 8)
    tmp_fil=${tmp_dir}/trigger-pipeline-${rand}-out.json
    header_result_file=${tmp_dir}/trigger-pipeline-${rand}-header

}

init

### environment
k=environment
v=${PIPELINE_PARM_ENVIRONMENT}
parms=$(jq -n --arg k "$k" --arg v "$v" 'setpath(["parameters",$k]; $v)')

### aws-credentials-context
k=aws-credentials-context
v=${PIPELINE_PARM_CONTEXT}
parms=$(echo "$parms" | jq --arg k "$k" --arg v "$v" 'setpath(["parameters",$k]; $v)')

### workflow-name
k=workflow-name
v=${PIPELINE_PARM_WORKFLOW_NAME}
parms=$(echo "$parms" | jq --arg k "$k" --arg v "$v" 'setpath(["parameters",$k]; $v)')

###   action
k=action
v=${PIPELINE_PARM_ACTION}
parms=$(echo "$parms" | jq --arg k "$k" --arg v "$v" 'setpath(["parameters",$k]; $v)')

data=$(echo "$parms" | jq --arg branch "$CIRCLE_BRANCH" '. |= .+ {"branch":$branch}')

echo $data | jq .

# cirlce_ci_url="https://circleci.com/api/v2/project/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pipeline"

# curl --request POST \
#     --silent \
#     --output "$tmp_fil" \
#     --dump-header "$header_result_file" \
#     --header "Circle-Token: $CIRCLE_USER_TOKEN" \
#     --header "Content-Type: application/json" \
#     --header 'Accept: application/json' \
#     --data "${data}" \
#     $cirlce_ci_url

# jq . $tmp_fil

# rm $header_result_file
# rm $tmp_fil
