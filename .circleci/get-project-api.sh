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
    tmp_fil=${tmp_dir}/get-project-${rand}-out.json
    header_result_file=${tmp_dir}/get-project-${rand}-header
}

init

cirlce_ci_url="https://circleci.com/api/v2/project/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"
curl --request GET \
    --silent \
    --output "$tmp_fil" \
    --dump-header "$header_result_file" \
    --header "Circle-Token: $CIRCLE_USER_TOKEN" \
    --header "Content-Type: application/json" \
    --header 'Accept: application/json' \
    $cirlce_ci_url

jq . $tmp_fil

rm $header_result_file
rm $tmp_fil

