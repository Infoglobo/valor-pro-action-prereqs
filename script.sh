#!/usr/bin/env bash

function log() {
    S=$1
    echo $S | sed 's/./& /g'
}
uses() {
    [ ! -z "${1}" ]
}

set -x 
echo "$(pwd)"

COUNT=$( find . -type f -iname "launchSettings.json" | wc -l )

if [ "$COUNT" -gt "1" ]; then
  echo "Existe mais de um arquivo launchSettings.json no projeto"
  find . -type f -iname "launchSettings.json"
  exit 1
fi

LAUNCHSETTINGS_FILES=$(find . -type f -iname "launchSettings.json")
FIRST_LAUNCHSETTINGS=$(echo "$LAUNCHSETTINGS_FILES" | head -n 1)

echo "$FIRST_LAUNCHSETTINGS"

SUCCESS=true
if [ ! -z "$FIRST_LAUNCHSETTINGS" ]; then
    ENV_PROPS=$(env)

    AMBIENTE=${GITHUB_REF_NAME##*/}
    AMBIENTE=${AMBIENTE,,}
    #garantir que a pasta seja sempre enviroments/main
    if [ "$GITHUB_REF_NAME" == "master" ] || [ "$GITHUB_REF_NAME" == "main"  ] ; then
        AMBIENTE="main"
    fi 
    
    PROPERTY_FILE="$FOLDER_REPO_NAME/enviroments/$AMBIENTE/cm.properties"


    if  [ -s "$PROPERTY_FILE" ]; then
        while IFS='=' read -r k v; do
            ENV_PROPS="${ENV_PROPS}\n$k=$v"
        done < $PROPERTY_FILE
    fi



    #echo "$ENV_PROPS"
    #remove caracateres invalidos para o json
    sed -i '/^[[:space:]]*\/\/.*/d'  "$FIRST_LAUNCHSETTINGS"

    for O in $( jq -r '.. | select(.environmentVariables?).environmentVariables | keys[]' "$FIRST_LAUNCHSETTINGS" ); do
        #echo $row
        if [[ ! "$ENV_PROPS" =~ $O ]] ; then 
            echo "** property $O não encontrada" ;   
            SUCCESS=false
        else 
            echo "property $O encontrada" ;   
        fi
    done
fi


if [ ! "$SUCCESS" ] ; then
    echo "falha"
    exit 1;
fi