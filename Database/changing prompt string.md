202207020832
Tags: #linux

---

# changing prompt string

```bash
# backup
PS_BACKUP="${PS1}"

# red
PS1='\[\033[0;31m\]\A \u@\h $ \[\033[0;37m\['

# blue bgc
PS1='\[\033[0;44m\]\A \u@\h $ \[\033[0;37m\['

# red square with time on the top
$PS1="\[\033[s\033[0;0H\033[0;41m\033[K\033[1;33m\t\033[0m\033[u\]<\u@\h \W>\$ "
```

---
## Links