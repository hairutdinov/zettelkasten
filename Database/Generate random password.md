202206130943
Tags: #bash_script

---

# Generate random password
```bash
#!/bin/bash

# Generate a list of random passwords.

# A random number as a password
PASSWORD="${RANDOM}"
echo "${PASSWORD}"

# Use the current date/time as the basis for the password
PASSWORD=$(date +%s)
echo "${PASSWORD}"

# Use nanoseconds to act as randomizer.
PASSWORD=$(date +%s%N)
echo "${PASSWORD}"

# A better password 
PASSWORD=$(date +%s%N | sha256sum | head -c18)
echo "${PASSWORD}"

# An even better password.
PASSWORD=$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c48)
echo "${PASSWORD}"

CHARS='!@#$%^&*()_+='
SPECIAL_CHARACTER=$(echo "${CHARS}" | fold -w1 | shuf | head -c1)
echo "${PASSWORD}${SPECIAL_CHARACTER}"

```

---
## Links