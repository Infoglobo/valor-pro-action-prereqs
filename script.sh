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
  #echo "$ENV_PROPS"

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
   exit 1;
fi