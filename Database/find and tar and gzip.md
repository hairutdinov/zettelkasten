202207072250
Tags: #linux

---

# find and tar and gzip

```bash
find playground/ -type f -iname file-e | tar cf - --files-from=- | gzip > playground_e_files.tgz
# or easier
find playground/ -type f -iname file-g | tar czf playground_g_files.tgz -T -

# show list of files
gunzip -c playground_e_files.tgz | tar t
```

---
## Links