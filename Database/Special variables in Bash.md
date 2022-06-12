202206121806
Tags: #bash_script

---

# Special variables in Bash

```bash
# Display the UID
echo "${UID}" 

# Display the username
USERNAME="$(id -un)"
# alternative 
USERNAME=`id -un)`

echo "Your username is: ${USERNAME}"
```

---
## Links
- [[Variable in Bash]]