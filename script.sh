#!/usr/bin/env bash

function log() {
    S=$1
    echo $S | sed 's/./& /g'
}
uses() {
    [ ! -z "${1}" ]
}

echo "$(pwd)"

LAUNCHSETTINGS_FILES=$(find . -type f -iname "launchSettings.json")
FIRST_LAUNCHSETTINGS=$(echo "$files" | head -n 1)

echo $FIRST_LAUNCHSETTINGS

SUCCESS=true
if [ ! -z $FIRST_LAUNCHSETTINGS ]; then
  APP_NAME=$(sed -n '0,/^ENTRYPOINT/s/.*"\([^"]*\)\.Api\.dll".*/\1/p' Dockerfile)
  ENV_PROPS=$(env)
  echo "$ENV_PROPS"

  for O in $( jq -r ".profiles.\"$APP_NAME\".environmentVariables | keys[]" $FIRST_LAUNCHSETTINGS ); do
    #echo $row
    if [[ ! "$ENV_PROPS" =~ "$O" ]] ; then 
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