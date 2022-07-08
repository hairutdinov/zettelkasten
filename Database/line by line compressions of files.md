202207081432
Tags: #linux

---

# line by line compressions of files

```bash
# first column - unique lines from file1
# second column - unique lines from file2
# third - identical lines
comm file1 file2

# show only identical lines
comm -12 file1 file2
```

---
## Links