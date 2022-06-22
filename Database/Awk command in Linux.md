202206222154
Tags: #linux #bash_script 

---

# Awk command in Linux

```bash
# if delimiter more than 1 character
awk -F 'DATA:' '{print $2,$3}' awk.temp

# change output delimiter
awk -F 'DATA:' -v OFS=',' '{print $2,$3}' awk.temp
 
 # print formatting
 awk -F 'DATA:' '{print $2 ";" $3}' awk.temp
 
 ```

---
## Links