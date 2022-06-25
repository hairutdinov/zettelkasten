202206232208
Tags: #linux #bash_script

---

# Get ports numbers in Linux

```bash
# -4 - for tcp version 4
# -n - Show numerical addresses instead of trying to determine symbolic host, port or user names.
# -u - UDP
# -t - TCP
# -l - Show only listening sockets.
netstat -4nutl | grep ':' | awk '{print $4}' | awk -F ':' '{print $NF}'
# other way
netstat -4nutl | grep ':' | awk '{print $4}' | cut -d ':' -f 2
```

---
## Links