202206212210
Tags: #bash_script

---

# Create test users in Bash

```bash
#!/bin/bash

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run with sudo or root' >&2
  exit 1
fi

for USERNAME in testuser1 testuser2 testuser3 testuser4
do
        PASSWORD=$(date +%s%N | sha256sum | head -c18)
        useradd -m ${USERNAME} &> /dev/null
        echo "${USERNAME}:${PASSWORD}" | chpasswd &> /dev/null
        echo "Username: ${USERNAME}"
        echo "Password: ${PASSWORD}"
done
```

---
## Links