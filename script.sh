#!/usr/bin/env bash

function log() {
    S=$1
    echo $S | sed 's/./& /g'
}
uses() {
    [ ! -z "${1}" ]
}

files=$(find . -type f -iname "launchSettings.json")
first_file=$(echo "$files" | head -n 1)

echo $first_file

SUCCESS=true
if [ ! -z $first_file ]; then
  APP_NAME=$(sed -n '0,/^ENTRYPOINT/s/.*"\([^"]*\)\.Api\.dll".*/\1/p' Dockerfile)
  ENV_PROPS=$(env)
  echo "$ENV_PROPS"
  #jq -r .profiles.\"$APP_NAME\".environmentVariables $first_file
  #jq '.profiles."Valor.Pro.Historical.Series".environmentVariables' $first_file 
  #jq '.profiles."Valor.Pro.Historical.Series.Api".environmentVariables' ./src/valor.pro.historical.series.api/Properties/launchSettings.json
  for O in $( jq -r ".profiles.\"$APP_NAME\".environmentVariables | keys[]" $first_file ); do
    #echo $row
    if [[ ! "$ENV_PROPS" =~ "$O" ]] ; then 
        echo "$O não encontrada" ;   
        SUCCESS=false
    fi
  done
fi


if [ ! "$SUCCESS" ] ; then
   exit 1;
fi