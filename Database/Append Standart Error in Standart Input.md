202206132110
Tags: #bash_script

---

# Append Standart Error in Standart Input

```bash
# 2 - descriptor for Standart Err
# and we redirecting it to &1, which represents file descriptor 1 -> which represents Standart Output
head -n1 /etc/passwd /etc/hosts /fakefile 2>&1 | cat -n
# another syntax
head -n1 /etc/passwd /etc/hosts /fakefile |& cat -n
```

---
## Links