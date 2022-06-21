202206212217
Tags: #bash_script

---

# Delete local users in Bash

```bash
#!/bin/bash

ARCHIVE_DIR='/archive'
DELETE_USER='false'
ARCHIVE='false'

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run with sudo or root' >&2
  exit 1
fi


usage () {
	echo "Usage: ${0} [-dra] USER [USER] ..." >&2
       	echo "Delete local user account " >&2
	echo '	-d Deletes account instead of disabling' >&2
	echo '	-r Removes home dir' >&2
	echo '	-a Archives home dir' >&2
	exit 1
}

# parse the options 
while getopts dra OPTION
do
	case ${OPTION} in
		d)
			DELETE_USER='true'
			;;
		r)
			REMOVE_OPTION='-r'
			;;
		a)
			ARCHIVE='true'
			;;
		?)
			usage
			;;
	esac
done

# remove the options while leaving remaining arguments

shift "$(( OPTIND - 1 ))"

if [[ "${#}" -lt 1 ]]
then
	usage
fi

# loop through all the usernames 
for USERNAME in "${@}"
do
	echo "Processing user ${USERNAME}"
	# make sure UID greather than 1000
	USERID=$(id -u ${USERNAME})
	if [[ ${USERID} -lt 1000 ]]
	then
		echo "Refusing to remove the account ${USERNAME} with UID ${USERID}" >&2
		exit 1
	fi

	# create an archive if requested
	if [[ "${ARCHIVE}" = 'true' ]]
	then
		# archive dir exists
		if [[ ! -d "${ARCHIVE_DIR}" ]]
		then
			echo "Creating ${ARCHIVE_DIR} directory"
			mkdir -p ${ARCHIVE_DIR}
			if [[ "${?}" -ne 0 ]]
			then
				echo "The arcive directory ${ARCHIVE_DIR} could not be created" >&2
				exit 1
			fi
		fi

		# archive user's home dir and move it to ${ARCHIVE_DIR}
		HOME_DIR="/home/${USERNAME}"
		ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
		if [[ -d "${HOME_DIR}" ]]
		then
			echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
			tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
			if [[ "${?}" -ne 0 ]]
			then
				echo "Couldn't create ${ARCHIVE_FILE}" >&2
				exit 1
			fi
		else
			echo "${HOME_DIR} doesn't exist or it's not a directory" >&2
			exit 1
		fi
	fi

	if [[ "${DELETE_USER}" = 'true' ]]
	then
		# delete the user
		userdel ${REMOVE_OPTION} ${USERNAME} 2> /dev/null
		if [[ "${?}" -ne 0 ]]
		then
			echo "the account ${username} was not deleted" >&2
			exit 1
		fi
		echo "The account ${USERNAME} was deleted"
	else
		chage -E 0 ${USERNAME}
		if [[ "${?}" -ne 0 ]]
		then
			echo "the account ${username} was not disabled" >&2
			exit 1
		fi
		echo "The account ${USERNAME} was disabled"
	fi
done

exit 0

```

---
## Links