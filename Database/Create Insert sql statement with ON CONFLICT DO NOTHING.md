202207011145
Tags: #bash_script

---

# Create Insert sql statement with ON CONFLICT DO NOTHING

```bash
#!/bin/bash

usage () {
	echo "Usage: ${0} [-nt] " >&2
       	echo "Creates INSERT sql file with ON CONFLICT DO NOTHING statement" >&2
	echo '	-n schema' >&2
	echo '	-t table' >&2
	exit 1
}

DATABASE='medclinics'
SCHEMA=''
TABLE=''

while getopts n:t:d OPTION
do
  case ${OPTION} in
    n)
      SCHEMA="${OPTARG}" ;;
    t)
      TABLE="${OPTARG}" ;;
    d)
      DRY_RUN='true' ;;
    ?)
      usage ;;
  esac
done

if [[ "${SCHEMA}" = '' ]] 
then
  echo "Option -n is required" >&2
  usage
fi

if [[ "${TABLE}" = '' ]] 
then
  echo "Option -t required" >&2
  usage
fi

FILE="${SCHEMA}_${TABLE}.sql"

echo "Creating ${FILE}"

# COMMAND="pg_dump -U postgres --column-inserts --data-only -t ${SCHEMA}.${TABLE} ${DATABASE} > ${FILE}"
# COMMAND="pg_dump -U postgres --column-inserts --data-only -t ${SCHEMA}.${TABLE} ${DATABASE} | sed -e '/^INSERT/!d' -e '/\x27);$/! s/$/\x27);/' -e 's/;$/ ON CONFLICT DO NOTHING;/ '> ${FILE}"
COMMAND="pg_dump -U postgres --column-inserts --data-only -t ${SCHEMA}.${TABLE} ${DATABASE} | sed -e '/^INSERT/, /);$/!d' -e 's/;$/ ON CONFLICT DO NOTHING;/ '> ${FILE}"

if [[ "${DRY_RUN}" = 'true' ]]
then
  echo ${COMMAND}
  exit 0
fi

eval "${COMMAND}"
exit 0
```

---
## Links