202207080723
Tags: #linux

---

# find files with empty spaces in name

```bash
find . -maxdepth 1 -regex '.*[^-_./0-9a-zA-Z].*'
```

---
## Links