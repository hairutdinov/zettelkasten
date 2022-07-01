202206282237
Tags: #linux

---

# Search in History in Linux

```bash
$ history | less

  861  ls 201
  862  ls 2015 2016 2017 2018 2019 2020
  863  ls -d 2020
  864  ls -d 2015 2016 2017 2018 2019
  865  ls -ld 2015 2016 2017 2018 2019
  866  ls -d 2015 2016 2017 2018 2019
  867  ls -ld 2015 2016 2017 2018 2019
  868  set | less
  869  history
  
$ !863
ls -d 2020
...
```

## Reverse search through the bash history
- CTRL + R - start
- ENTER - execute
- CTRL + J - set in current command

---
## Links