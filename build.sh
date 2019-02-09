#!/bin/bash

# set -x

PROGNAME=$(basename $0)

usage() {
    echo "USAGE: ${PROGNAME} [-t TAG]"
}

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
    exit 2
}

usageErrorExit() {
    echo "${PROGNAME}: ${1}" 1>&2
    echo ""
    usage
    exit 1
}

dockerfile=Dockerfile
repoName="dankempster/jenkins-ansible"
tag="build"

while [ "$1" != "" ]; do
    case $1 in
        -d | --docker )
            shift
            dockerfile=$1
            ;;
        -r | --repository )
            shift
            repoName=$1
            ;;
        -t | --tag )
			shift
            tag=$1
            ;;
        * )
            usageErrorExit "Unknown argument '${1}'"
    esac
    shift
done

baseImage="geerlingguy/docker-debian9-ansible:latest"

docker pull $baseImage
echo ""
bin/docker-playbook.sh \
    -d $dockerfile \
    -c /lib/systemd/systemd \
    -p 8080 \
    -p 50000 \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -t "${repoName}:${tag}"
