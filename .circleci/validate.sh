APIGWNAME=${DEPLOY_ENVIRONMENT}-serverless-http-api-dynamodb
APIGWURL=$(aws apigatewayv2 get-apis | jq --arg gwname ${APIGWNAME} '.Items[] | select(.Name == $gwname) | .ApiEndpoint' | jq -r .) && echo "Our APIGW URL is : ${APIGWURL}"
RAND=$(openssl rand -hex 8) && echo "Our Random Tracking Code is : ${RAND}"

# create data blob
DATA=$(echo "{\"text\":\"${RAND}\"}" | jq .)


# test create api
# push data
response_file="${RAND}_01_create"
status_code=$(curl -s --output "$response_file" -w "%{http_code}" -X POST ${APIGWURL}/todos --header "Content-Type: application/json" --data "${DATA}")

if [ "${status_code}" -ge "200" ] && [ "${status_code}" -lt "300" ]; then
    expected_id=$(jq -r ".id" "${response_file}")
    echo "Expected ID is : ${expected_id}"
else
    echo "API call failed [${status_code}]. Response: "
    cat "${response_file}"
    exit 1
fi

# test list api
# get all Todos Back
response_file="${RAND}_02_list"
status_code=$(curl -s --output "$response_file" -w "%{http_code}" $APIGWURL/todos)
if [ "${status_code}" -ge "200" ] && [ "${status_code}" -lt "300" ]; then
    TODOSFILE=${response_file}
    echo "All Todos Stored in : ${response_file}"
else
    echo "API call failed [${status_code}]. Response: "
    cat "${response_file}"
    exit 1
fi

# find our marker
if [ $(jq --arg rand $RAND '.[] | select(.text == $rand) | .id ' ${TODOSFILE} | jq -r . | wc -l ) -eq 1 ]
then
    TODOID=$(jq --arg rand $RAND '.[] | select(.text == $rand) | .id ' ${TODOSFILE} | jq -r .)
    echo "Our TODOID is : ${TODOID}"
else
    echo "API Called Multiple Times; Multiple Records Found"
    cat "${TODOSFILE}"
    exit 1
fi

# validate our marker
if [ ${TODOID} == ${expected_id} ]
then
    echo "Our TODOID matches expected_id"
else
    echo "Our TODOID does not match expected_id"
    exit 1
fi

# test get api
# check the exact item
response_file="${RAND}_03_get"
status_code=$(curl -s --output "$response_file" -w "%{http_code}" $APIGWURL/todos/${TODOID})
if [ "${status_code}" -ge "200" ] && [ "${status_code}" -lt "300" ]; then
    found_id=$(jq -r .text ${response_file})
    if [ ${found_id} == ${RAND} ]
    then
        echo "Item Retrieved Successfully"
    else
        echo "Item text does not match expected result"
        echo "Found    : ${found_id}"
        echo "Expected : ${RAND}"
        exit 1
    fi
else
    echo "API call failed [${status_code}]. Response: "
    cat "${response_file}"
    exit 1
fi

# test update api
# update the exact item
DATA=$(echo $DATA | jq '. |= .+ {"checked": true}')
response_file="${RAND}_04_update"
status_code=$(curl -s --output "$response_file" -w "%{http_code}" -X PUT ${APIGWURL}/todos/${TODOID} --header "Content-Type: application/json" --data "${DATA}")
if [ "${status_code}" -ge "200" ] && [ "${status_code}" -lt "300" ]; then
    found_checked=$(jq -r .checked ${response_file})
    if [ "${found_checked}" == "true" ]
    then
        echo "Item Updated Successfully"
    else
        echo "Item text does not match expected result"
        echo "Found    : ${found_checked}"
        echo "Expected : true"
        exit 1
    fi
else
    echo "API call failed [${status_code}]. Response: "
    cat "${response_file}"
    exit 1
fi

# test delete
# delete the exact item
response_file="${RAND}_05_delete"
status_code=$(curl -s --output "$response_file" -w "%{http_code}" -X DELETE ${APIGWURL}/todos/${TODOID} --header "Content-Type: application/json" --data "${DATA}")
if [ "${status_code}" -ge "200" ] && [ "${status_code}" -lt "300" ]; then
    response_file="${RAND}_05_delete_validate"
    status_code=$(curl -s --output "$response_file" -w "%{http_code}" $APIGWURL/todos/${TODOID})
    if [ "${status_code}" -ge "200" ] && [ "${status_code}" -lt "300" ]; then
        if [ $(cat ${response_file} | wc -l) -eq 0 ]
        then
            echo "Item Deleted Successfully"
        else
            echo "Items Still found After Delete"
            exit 1
        fi
    fi
else
    echo "API call failed [${status_code}]. Response: "
    cat "${response_file}"
    exit 1
fi

# do final cleanup
for fil in $(ls | grep ${RAND})
do
    rm ${fil}
done