202206132126
Tags: #bash_script

---

# Null device in Bash

```bash
# send STDERR to /dev/null
head -n1 /etc/passwd /etc/hosts /fakefile 2> /dev/null
```

---
## Links