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

baseImage=""
playbook="playbook.yml"
repository=""


cleanUp() {
	docker rm -v $(docker stop $1)
}

cleanUpTrap() {
	echo ""
	echo ""
	echo ""
	echo "Recieved signal... cleaning up..."
	echo ""
	cleanUp
	exit 1
}

startBase() {
	docker run -dt -v $(pwd):/project $1 bash -i
}

usage() {
	echo "USAGE: ${PROGNAME} [-p PLAYBOOK] -b BASE_IMAGE -r REPOSITORY[:TAG]"
}

if [ $# -eq 0 ]; then
	echo "ERROR: Missing arguments" 1>&2
    usage
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        -b | --base )
			shift
            baseImage=$1
            ;;
        -p | --playbook )
			shift
            playbook=$1
            ;;
        -r | --repository )
			shift
            repository=$1
            ;;
        * )                   
            usage
            exit 1
    esac
    shift
done

containerId=$(startBase $baseImage)

# Clean up the continer if we recieved one of these signals before
#   terminating the script
trap "cleanUpTrap $continerId" SIGHUP SIGINT SIGTERM

echo "Building in container: ${containerId}"

# Run the playbook
docker exec -t -w /project $containerId ansible-playbook $playbook

# Create the image from the container
docker commit -p -a "Dan Kempster <me@dankempster.co.uk>" $containerId $repository

echo "Used $containerId to create ${repository}"

# Clean up
cleanUp $containerId
