#!/bin/bash

# set -x

PROGNAME=$(basename $0)

errorExit() {
#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string : descriptive error message
#	----------------------------------------------------------------
#
#   Example call of the error_exit function.  Note the inclusion
#   of the LINENO environment variable.  It contains the current
#   line number.
#
#	   error_exit "$LINENO: An error has occurred."
#
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

usage() {
	echo "USAGE: ${PROGNAME} [-t TAG]"
}

repoName="dankempster/jenkins"
tag="build"

while [ "$1" != "" ]; do
    case $1 in
        -t | --tag )
			shift
            tag=$1
            ;;
        * )                   
            usage
            exit 1
    esac
    shift
done

baseImage="geerlingguy/docker-debian9-ansible:latest"

docker pull $baseImage
echo ""
bin/docker-playbook.sh -p playbook.yml -b $baseImage -r $repoName:$tag
