202206132240
Tags: #bash_script

---

# Create User bash script Improved Version

```bash
#!/bin/bash

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run with sudo or root' >&2
  exit 1
fi

# If the user doesn't supply at least one argument, then give them help.
if [[ "${#}" -lt 1 ]]
then
  echo "Usage: ${0} LOGIN [FULL_NAME]..." >&2
  exit 1
fi 

# The first parameter is the user name.
LOGIN="${1}"

# The rest of the parameters are for the account comments.
shift
COMMENT="${@}"

# Generate a password.
PASSWORD=$(date +%s%N | sha256sum | head -c18)

# Create the user with the password.
useradd -m -c "${COMMENT}" ${LOGIN} &> /dev/null

# Check to see if the useradd command succeeded.
if [[ "${?}" -ne 0 ]]
then
  echo 'Error while creating user' >&2
  exit 1
fi

# Set the password.
echo "${LOGIN}:${PASSWORD}" | chpasswd &> /dev/null

# Check to see if the passwd command succeeded.
if [[ "${?}" -ne 0 ]]
then
  echo "Error while setting the password for user: ${LOGIN}" >&2
  exit 1
fi

# Force password change on first login.
passwd -e ${LOGIN} &> /dev/null

# Display the username, password, and the host where the user was created.
echo "Username: ${LOGIN}"
echo "Password: ${PASSWORD}"
echo "Host: ${HOSTNAME}"
exit 0
```

---
## Links
- [[Create User bash script]]