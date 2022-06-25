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
```

---
## Links