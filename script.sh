#!/usr/bin/env bash

function log() {
    S=$1
    echo $S | sed 's/./& /g'
}
uses() {
    [ ! -z "${1}" ]
}

function addBlankLineToFile() {
    FILE=$1
    if  [ ! -f "$FILE" ]; then
        touch  "$FILE"
    fi
    sed -i -e '$a\' "$FILE"
}

#set -x 
echo "$(pwd)"
ls -lha 

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
    ENV_PROPS=

 

    AMBIENTE=${GITHUB_REF_NAME##*/}
    AMBIENTE=${AMBIENTE,,}
 

    SECRETS_PREFIX=${AMBIENTE^^}

    if [ "$GITHUB_REF_NAME" = "dev" ] ; then
        SECRETS_PREFIX="DEV"
    elif [ "$GITHUB_REF_NAME" = "homolog" ] ; then
        SECRETS_PREFIX="HML"
    elif [ "$GITHUB_REF_NAME" == "master" ] || [ "$GITHUB_REF_NAME" == "main"  ] ; then
        SECRETS_PREFIX="PRD"
        #garantir que a pasta seja sempre enviroments/main
        AMBIENTE="main"
    fi  
    SECRETS_PREFIX=${SECRETS_PREFIX^^}


    env | grep ^"$SECRETS_PREFIX" | 
    while IFS='=' read -r key value; do
        key="${key/#${SECRETS_PREFIX}_/}"
        echo "ENV_PROPS carregando $key das secrets do github" 
        ENV_PROPS="${ENV_PROPS}\n$key=$value"
    done 

    FOLDER_REPO_NAME=$(pwd)
    PROPERTY_FILE="$FOLDER_REPO_NAME/enviroments/$AMBIENTE/cm.properties"
    addBlankLineToFile "$PROPERTY_FILE"
    cat $PROPERTY_FILE
    # verifica se o arquivo existe e não está vazio e carrega as propriedades
    if  [ -s "$PROPERTY_FILE" ]; then
        echo "carregando as propriedades do arquivo $PROPERTY_FILE"
        while IFS='=' read -r key value; do
            echo "ENV_PROPS carregando $key do arquivo  $PROPERTY_FILE" 
            ENV_PROPS="${ENV_PROPS}\n$key=$value"
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