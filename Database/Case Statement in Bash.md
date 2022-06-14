 202206140805
Tags: #bash_script

---

# Case Statement in Bash

```bash
case "${1}" in
  start) echo 'Starting.';;
  stop) echo 'Stopping.';;
  status) echo 'Status: ';;
  # *) echo 'Supply a valid option' >&2; exit 1;;
  *)
    echo 'Supply a valid option' >&2
    exit 1
    ;;
esace
```

---
## Links