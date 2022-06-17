202206180019
Tags: #bash_script

---

# remove the options while leaving the remaining arguments in bash

```bash
# remove the options while leaving the remaining arguments.
shift "$(( OPTIND - 1))"

echo "After the shift: ${@}"
```

---
## Links