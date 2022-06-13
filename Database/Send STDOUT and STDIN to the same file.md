202206132100
Tags: #bash_script

---

# Send STDOUT and STDIN to the same file

```bash
# Old syntax
head -n1 /etc/passwd /etc/hosts /fakefile 1> head.both 2>&1

# New syntax
head -n1 /etc/passwd /etc/hosts /fakefile &> head.both
```

---
## Links