202206142044
Tags: #bash_script

---

# Getopts in Bash

```bash
#!/bin/bash

# this script generates a random passwoed.
# -l - for the password length
# -s - for add special character
# -v - verbose mode

usage() {
	echo "Usage: ${0} [-vs] [-l LENGTH]" >&2
	echo "Generate a random password"
	echo "   -l LENGTH  Specify the password length."
	echo "   -s         Append a special character to the password."
	echo "   -v         Increase Verbosity."
	exit 1
}

log() {
	local MESSAGE="${@}"
	if [[ "${VERBOSE}" = 'true' ]]
	then
		echo "${MESSAGE}"
	fi
}

# Default pass length
LENGTH=48

while getopts vl:s OPTION
do
	case ${OPTION} in
		v)
			VERBOSE='true'
			log 'Verbose mode on.'
			;;
		l)
			LENGTH="${OPTARG}"
			;;
		s)
			USE_SPECIAL_CHARACTER='true'
			;;
		?)
			usage
			;;
	esac
done

log 'Generating a passowrd.'

PASSWORD=$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c${LENGTH})
if [[ "${USE_SPECIAL_CHARACTER}" = 'true' ]]
then
	log 'Selecting a random special characted.'
	SPECIAL_CHAR=$(echo '!@#$%^&*()_+=' | fold -w1 | shuf | head -c1)
	PASSWORD="${PASSWORD}${SPECIAL_CHAR}"
fi

log 'Done.'
log "Password:"
echo "${PASSWORD}"
```

---
## Links