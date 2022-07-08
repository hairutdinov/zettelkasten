202206232215
Tags: #linux #bash_script

---

# Sorting in Linux

```bash
sort /etc/passwd

# reverse sorting
sort -r /etc/passwd

# sort /etc/passwd UID 
# -n - sort as number
awk -F ':' '{print $3}' /etc/passwd | sort -n

# show disk usage for /var dir in Human readable format and sort it with human readable format
sudo du -h /var | sort -h

# u - for unique
netstat -nutl | grep ':' | awk '{print $4}' | awk -F ':' '{print $NF}' | sort -nu

# ! uniq comare only current line with previous, "sort" command required
netstat -nutl | grep ':' | awk '{print $4}' | awk -F ':' '{print $NF}' | sort -n | uniq

# count repeating lines
netstat -nutl | grep ':' | awk '{print $4}' | awk -F ':' '{print $NF}' | sort -n | uniq -c

# count CRON logs
cat /var/log/syslog | awk '{print $5}' | grep CRON | wc -l

# alternative way with grep -c 
cat /var/log/syslog | awk '{print $5}' | grep -c CRON

# sort by third column (UID) and reverse 
cat /etc/passwd | sort -t ':' -k 3 -n -r


# sorting by a few keys
cat sort.txt
A 1
A 3
A 2
B 1
B 2
B 3
C 10
C 4
C 2
C 3
sort --key=1,1 --key=2n sort.txt
# result be like:
A 1
A 2
A 3
B 1
B 2
B 3
C 2
C 3
C 4
C 10

#sorting dates in american format mm/dd/yyyy
cat sort_dates.txt
some description : 01/13/2022
another : 07/08/2022
some : 01/01/2022
as : 11/12/2021

sort -t ':' -k^C.7 -k 2.1 -k 2.4 sort_dates.txt
# result
as : 11/12/2021
some : 01/01/2022
some description : 01/13/2022
another : 07/08/2022
```

---
## Links