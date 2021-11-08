#!/bin/bash


set -uo pipefail # à voir , -x << debug -e exit on errors

help_syntax() {
    echo -e "\e[1mSyntax: $0 [command] <options>\e[0m"
    echo "$0 list-images"
    echo "$0 list-tags <image> <tag>"
    echo "$0 delete-tags <image> <tag>"
    echo "$0 delete-image <image> (will just remove all tags and keep empty image)"
    echo "$0 verify-script (will validate your script)"
    echo -e "\e[36m\e[5mOptions:\e[0m"
    echo "-address=http://127.0.0.1:5000 (default private registry)"
    exit 0
}

list_images () {
    curl "${1:-http://127.0.0.1:5000}"/v2/_catalog|jq -r '.repositories[]'

}
list_tags () {

    curl -s "${1:-http://127.0.0.1:5000}"/v2/"$2"/tags/list|jq -r '.tags[]'
}

delete_tags () {
  mani="$3"
  echo "$mani"=sha256:85882f461cf3db2c743d8b17fdba79e522bc33af182f14bc7b6d45b6adb9adcf
  url="${1:-http://127.0.0.1:5000}"/v2/"$2"/manifests/sha256:85882f461cf3db2c743d8b17fdba79e522bc33af182f14bc7b6d45b6adb9adcf
  
  curl -vs -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X DELETE "${url}"
  
  sudo docker exec reg bin/registry garbage-collect /etc/docker/registry/config.yml
}

delete_image () {

    url="${1:-http://127.0.0.1:5000}"/v2/"$2"/manifests/sha256:4e4bc990609ed865e07afc8427c30ffdddca5153fd4e82c20d8f0783a291e241
    curl -vs -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X DELETE "${url}"
    sudo docker exec reg bin/registry garbage-collect /etc/docker/registry/config.yml
}

shellcheck() {
    SHELLCHECK_BIN="$(which shellcheck)"
    if [ -z "$SHELLCHECK_BIN" ]; then # man test : pour voir les options
        apt-get update && apt-get install -y shellcheck
        shellcheck # call funct again...
        return 0 # but exit because next steps in this functions depends on var SHELLCHECK_BIN
    fi
    "$SHELLCHECK_BIN" "$0"
    if ! "$SHELLCHECK_BIN" "$0"; then # $? << get previous exit code but here we will use directly the return code of the command (0 OK, else bad....)
        echo -e "\e[31m\e[5m\n!!! ERREURS A FIXER !!!\n\e[0m"
    fi
}


if [ "$#" -eq 0 ]; then # au cas où $1 n'existe pas
    help_syntax
fi

case "$1" in
  list-images) echo "All images ..."
               list_images "$2"
               ;;
  list-tags) list_tags "$2" "$3";;
  delete-tags) delete_tags "$2" "$3" "$4";;
  delete-image) delete_image "$2" "$3";;
  verify-script) shellcheck;;
  *) help_syntax;;
esac
