202207072132
Tags: #linux

---

# find and xargs working with files contains spaces

```bash
find . -type f -name *.jpg -print0 | xargs --null ls -l
```

---
## Links