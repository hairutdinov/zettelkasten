202206122033
Tags: #bash_script

---

# Create User bash script
```bash
#!/bin/bash

# Ask for the user name
read -p 'Enter the username: ' USER_NAME

# Ask for the real name
read -p 'Enter the name of the person who this account is for: ' COMMENT

# Ask for the password
read -p 'Enter the password: ' PASSWORD

# Add user
useradd -m -c "${COMMENT}" ${USER_NAME}

# add password for the user
# echo ${PASSWORD} | passwd --stdin ${USER_NAME}
echo "${USER_NAME}:${PASSWORD}" | chpasswd

# Immediately expire an account's password.  
passwd -e ${USER_NAME}

```

---
## Links