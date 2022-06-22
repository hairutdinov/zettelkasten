202206212228
Tags: #linux #bash_script 

---

# Cut command in Linux

```bash
# first character for each line
cut -c 2 /etc/passwd

# staring and ending position
cut -c 4-7 /etc/passwd

# staring from 4 to the end of the line
cut -c 4- /etc/passwd

# first 4 characters
cut -c -4 /etc/passwd

# first field/column
echo -e 'first_column\tsecond_column\tthird_column' | cut -f 1

#first field/column with comma delimiter
echo 'a1,b1,c1
a2,b2,c2' | cut -f 1 -d ','

# print username and uid and set output delimiter
cat /etc/passwd | cut -d ':' --output-delimiter=',' -f 1,3
```

---
## Links