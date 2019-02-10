#!/bin/bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -gt 0 ]; then
        >&2 echo "\"${last_command:-Unknown}\" command failed with exit code ${exit_code}."
        cleanUp
        exit $exit_code
    fi
}

# enable !! command completion
set -x -o history -o histexpand

PROGNAME=$(basename $0)

usage() {
    echo "USAGE: ${PROGNAME} FILE NAME STATUS [MSG]"
    echo ""
    echo "FILE:"
    echo "  Where to save the jUnit file."
    echo ""
    echo "NAME:"
    echo "  The name of the UAT"
    echo ""
    echo "Status:"
    echo "  -p | --pass : UAT passed"
    echo "  -f | --fail : UAT failed"
    echo ""
    echo "MSG:"
    echo "  An optional message to include"
    echo ""
    echo "Examples:"
    echo ""
    echo "  To specify that the 'jenkins-config' UAT failed:"
    echo ""
    echo "    $ ${PROGNAME} jenkins-config -f 'Port 8080 unavailable'"
    echo ""
    echo ""
    echo "  To specify that the 'my-uat' UAT succeeded:"
    echo ""
    echo "    $ ${PROGNAME} my-uat -p"
    echo ""
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


if [ $# -lt 2 ]; then
    echo "ERROR: Missing arguments" 1>&2
    usage
    exit 1
fi

file=$1
shift
name=$1
shift
status=$1
case $1 in
    -f | --fail )
        status="fail"
        ;;
    -p | --pass)
        status="pass"
        ;;
    * )
        usageErrorExit "Unknown status '${1}'"
esac
shift
message=$@


if [ "${status}" == "pass" ]; then
	if [ "${message}" == "" ]; then
		message="SUCCESS"
	fi
	cat >${file} <<EOL
<?xml version="1.0" encoding="utf-8"?>
<testsuite errors="0" failures="0" name="molecule" skipped="0" tests="1" time="00.001">
    <testcase name="${name}" time="00.001">
    	<system-out>${message}</system-out>
    </testcase>
</testsuite>
EOL

elif [ "${status}" == "fail" ]; then
	if [ "${message}" == "" ]; then
		message="FAILURE"
	fi
	cat >${file} <<EOL
<?xml version="1.0" encoding="utf-8"?>
<testsuite errors="0" failures="1" name="molecule" skipped="0" tests="1" time="00.001">
    <testcase name="${name}" time="0.000">
    	<system-err>${message}</system-err>
    	<failure>${message}</failure>
    </testcase>
</testsuite>
EOL
fi
