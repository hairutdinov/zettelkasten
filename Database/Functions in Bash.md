202206142000
Tags: #bash_script

---

# Functions in Bash

```bash
!/bin/bash

#function log {
#  local MESSAGE="${@}"
#  echo "Function arguments: ${MESSAGE}"
#}

log() {
  local VERBOSE="${1}"
  shift
  local MESSAGE="${@}"
  if [[ "${VERBOSE}" = 'true' ]]
  then
    echo "${MESSAGE}"
  fi
  logger -t "${0}" "${MESSAGE}"
}

backup_file() {
  # this function creates a baskup of a file. Returns non-zero status on error.
  local FILE="${1}"

  # file exists
  if [[ -f "${FILE}" ]]
  then
    local BACKUP_FILE="/var/tmp/$(basename ${FILE}).$(date +%F-%N)"
    log 'true' "Backing up ${FILE} to ${BACKUP_FILE}."

    cp -p ${FILE} ${BACKUP_FILE}
  else
    exit 1
  fi
}

# readonly VERBOSITY='true'
VERBOSITY='true'
log "${VERBOSITY}" 'Hello'
log "${VERBOSITY}" 'Its me'

backup_file '/etc/passwd'

if [[ "${?}" -eq '0' ]]
then
  log 'true' "File backup succeded"
else
  log 'true' "File backup failed"
  exit 1
fi
```

---
## Links