202206210935
Tags: #bash_script

---

# Make sure script running with sudo or root in Bash

```bash
# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run with sudo or root' >&2
  exit 1
fi
```

---
## Links