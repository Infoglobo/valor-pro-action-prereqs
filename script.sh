#!/usr/bin/env bash
set -e
set -x

echo "Running action valor-pro-action-prereqs"

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

    ENV_PROPS=""

    FOLDER_REPO_NAME=$(pwd)
    PROPERTY_FILE="$FOLDER_REPO_NAME/enviroments/$AMBIENTE/cm.properties"

    #cat $PROPERTY_FILE
    # verifica se o arquivo existe e não está vazio e carrega as propriedades
    if  [ -s "$PROPERTY_FILE" ]; then
        addBlankLineToFile "$PROPERTY_FILE"

        #remove comentários
        sed -r -i -e '/^\s*$|^#/d' $PROPERTY_FILE
        #substitui ' = ' pr '='
        sed -r -i -e 's/\s=\s/=/g' $PROPERTY_FILE

        ##ERRORS=$(grep -vE '^$' $PROPERTY_FILE | grep -vE '^\w[^=]*=.*[^=]' | wc -l)
        #permite propriedades sem valores
        ERRORS=$(grep -vE '^$' $PROPERTY_FILE | grep -vE '^\w[^=]*=.*' | wc -l)

        if [ "$ERRORS" -gt "0" ]; then
            echo "Existem erros no arquivo  $PROPERTY_FILE "
            grep -vE '^$' $PROPERTY_FILE | grep -vE '^\w[^=]*=.*[^=]' 
            exit 1
        fi

        echo "carregando as propriedades do arquivo $PROPERTY_FILE"
        while IFS='=' read -r key value; do
            echo "ENV_PROPS carregando do arquivo $key $PROPERTY_FILE" 
            ENV_PROPS="${ENV_PROPS}\n$key=$value"
        done < $PROPERTY_FILE

        echo "SHOW ENV_PROPS"
        echo "$ENV_PROPS"
        echo "SHOW ENV_PROPS END"    

    fi

    #env | grep ^"$SECRETS_PREFIX" | 
    #while IFS='=' read -r key value; do
#
    #    key="${key/#${SECRETS_PREFIX}_/}"
    #    echo "ENV_PROPS carregando das secrets do github $key " 
    #    ENV_PROPS="${ENV_PROPS}\n$key=$key"
    #    echo "$ENV_PROPS"
    #    
    #done 

    env | grep ^"$SECRETS_PREFIX" > temp.txt
    cat temp.txt

    while IFS='=' read -r key value; do
        key="${key/#${SECRETS_PREFIX}_/}"
        echo "ENV_PROPS carregando das secrets do GITHUB $key" 
        ENV_PROPS="${ENV_PROPS}\n$key=$value"
    done < temp.txt    
    
    echo "SHOW ENV_PROPS"
    echo "$ENV_PROPS"
    ENV_PROPS="${ENV_PROPS}\n**FIM SECRETS**"
    echo "$ENV_PROPS"
    echo "SHOW ENV_PROPS END"


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


if [ "$SUCCESS" = false ] ; then
    echo "check prereqs falha"
    exit 1;
fi
echo "check prereqs sucesso"