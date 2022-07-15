202207140806
Tags: #git

---

# git log

```bash
# patch - разница, внесенная в каждый коммит
git log -p 

# сокращенная статистика
git log --stat

git log --pretty=oneline
				 short
				 full
				 fuller

# find commit which contains "some_function"
git log -S some_function

# show logs only for file_2
git log -- file_2

# show commits log created before jun, 1st 2022
git log --before 2022-06-01
git log --since 2022-05-30 --before 2022-06-01 --no-merges


# show commits log contain message 'bug fix'
git log --grep 'bug fix'
```

![[telegram-cloud-photo-size-2-5366352300102238367-y.jpg]]

---
## Links